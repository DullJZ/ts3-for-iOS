import Foundation
import AVFoundation

protocol TS3OpusEncoder {
    func encode(pcm: [Float]) throws -> Data
}

protocol TS3OpusDecoder {
    func decode(packet: Data) throws -> [Float]
}

enum TS3OpusFactory {
    static func makeEncoder(sampleRate: Int32, channels: Int32, application: Int32) throws -> TS3OpusEncoder {
        #if canImport(Opus)
        return try OpusEncoderWrapper(sampleRate: sampleRate, channels: channels, application: application)
        #else
        throw TS3Error.notImplemented
        #endif
    }

    static func makeDecoder(sampleRate: Int32, channels: Int32) throws -> TS3OpusDecoder {
        #if canImport(Opus)
        return try OpusDecoderWrapper(sampleRate: sampleRate, channels: channels)
        #else
        throw TS3Error.notImplemented
        #endif
    }
}

final class TS3AudioEngine {
    private static let badAudioDeviceErrorCode = 560227702 // '!dev' / kAudioHardwareBadDeviceError

    struct Config {
        let sampleRate: Double
        let channels: AVAudioChannelCount
        let frameSize: AVAudioFrameCount
        let opusApplication: Int32

        static let voice = Config(sampleRate: 48_000, channels: 1, frameSize: 960, opusApplication: 2048)
    }

    private let config: Config
    private var engine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private var captureBuffer: [Float] = []
    private lazy var outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                                  sampleRate: config.sampleRate,
                                                  channels: config.channels,
                                                  interleaved: false)

    private let encoder: TS3OpusEncoder
    private var playbackStates: [PlaybackSource: PlaybackState] = [:]
    private var playbackVolume: Float = 1.0
    private var sourcePlaybackGains: [UInt16: Float] = [:]
    private var mutedPlaybackSources: Set<UInt16> = []
    private var inputGain: Float = 1.0
    private var transmitMode: TS3AudioTransmitMode = .pushToTalk
    private var voiceActivationThreshold: Float = 0.03
    private var prefersSpeakerOutput = true
    private var wasVoiceActive = false

    var onEncodedPacket: ((Data) -> Void)?
    var onLog: ((TS3LogLevel, String) -> Void)?

    private var isPlaybackRunning = false
    private var isCaptureRunning = false
    private var encodedPacketCount = 0
    private var droppedInputBufferCount = 0

    private struct PlaybackSource: Hashable {
        let clientId: UInt16
        let kind: Kind

        enum Kind: Hashable {
            case channel
            case whisper
        }
    }

    private struct PlaybackState {
        var playerNode: AVAudioPlayerNode
        var decoder: TS3OpusDecoder
        var sessionMarker: UInt8?
    }

    init(config: Config) throws {
        self.config = config
        self.encoder = try TS3OpusFactory.makeEncoder(sampleRate: Int32(config.sampleRate), channels: Int32(config.channels), application: config.opusApplication)
    }

    func preparePlayback() throws {
        if isPlaybackRunning { return }
        try configureSession(needsInput: isCaptureRunning)
    }

    func startCapture() throws {
        guard !isCaptureRunning else { return }
        let shouldResumePlayback = !playbackStates.isEmpty
        log(.debug, "starting capture; existing playback sources=\(playbackStates.count)")

        do {
            try startCaptureAttempt()
        } catch {
            let initialError = error
            log(.warning, "capture start failed: \(error.localizedDescription)")
            cleanupCaptureStartFailure(restorePlayback: false)

            if shouldRetryCaptureStart(after: error) {
                recreateEngine(reason: "capture-start-retry")
                do {
                    try startCaptureAttempt()
                    return
                } catch {
                    log(.warning, "capture retry failed: \(error.localizedDescription)")
                    cleanupCaptureStartFailure(restorePlayback: shouldResumePlayback)
                    throw captureStartError(from: error)
                }
            }

            cleanupCaptureStartFailure(restorePlayback: shouldResumePlayback)
            throw captureStartError(from: initialError)
        }
    }

    func stopCapture() {
        guard isCaptureRunning else { return }
        let shouldResumePlayback = !playbackStates.isEmpty
        if engine.isRunning {
            engine.stop()
        }
        engine.inputNode.removeTap(onBus: 0)
        converter = nil
        captureBuffer.removeAll()
        encodedPacketCount = 0
        droppedInputBufferCount = 0
        isCaptureRunning = false
        if shouldResumePlayback {
            try? configureSession(needsInput: false)
            rebuildPlaybackGraph()
            try? startEngineIfNeeded()
            isPlaybackRunning = engine.isRunning
            return
        }
        stopEngineIfIdle()
    }

    func stop() {
        stopCapture()
        guard isPlaybackRunning || engine.isRunning else { return }
        for state in playbackStates.values {
            detachPlayerNodeIfNeeded(state.playerNode)
        }
        playbackStates.removeAll()
        engine.stop()
        captureBuffer.removeAll()
        isPlaybackRunning = false
    }

    func setPlaybackVolume(_ volume: Float) {
        playbackVolume = min(max(volume, 0), 4)
    }

    func setPlaybackGain(_ gain: Float, for clientId: UInt16) {
        let clamped = min(max(gain, 0), 4)
        if clamped == 1 {
            sourcePlaybackGains.removeValue(forKey: clientId)
        } else {
            sourcePlaybackGains[clientId] = clamped
        }
    }

    func setPlaybackMuted(_ isMuted: Bool, for clientId: UInt16) {
        if isMuted {
            mutedPlaybackSources.insert(clientId)
        } else {
            mutedPlaybackSources.remove(clientId)
        }
    }

    func setInputGain(_ gain: Float) {
        inputGain = min(max(gain, 0), 4)
    }

    func setTransmitMode(_ mode: TS3AudioTransmitMode) {
        transmitMode = mode
        if mode != .voiceActivation {
            wasVoiceActive = false
        }
    }

    func setVoiceActivationThreshold(_ threshold: Float) {
        voiceActivationThreshold = min(max(threshold, 0.001), 0.5)
    }

    func setPrefersSpeakerOutput(_ prefersSpeaker: Bool) {
        prefersSpeakerOutput = prefersSpeaker
    }

    func handleIncoming(packet: Data, from clientId: UInt16, isWhisper: Bool, sessionMarker: UInt8?) {
        let source = PlaybackSource(clientId: clientId, kind: isWhisper ? .whisper : .channel)
        if packet.isEmpty {
            endPlayback(for: source)
            return
        }

        do {
            let state = try playbackState(for: source, sessionMarker: sessionMarker)
            let samples = try state.decoder.decode(packet: packet)
            playbackStates[source] = state
            play(samples: samples, from: source.clientId, on: state.playerNode)
        } catch {
            let route = isWhisper ? "whisper" : "channel"
            log(.warning, "playback failed for \(route) source \(clientId): \(error.localizedDescription)")
        }
    }

    private func configureSession(needsInput: Bool) throws {
        #if targetEnvironment(macCatalyst) || os(iOS)
        let session = AVAudioSession.sharedInstance()
        let options: AVAudioSession.CategoryOptions
        #if compiler(>=6.3)
        options = [.allowBluetoothHFP, .defaultToSpeaker]
        #else
        // Older Xcode SDKs do not expose `allowBluetoothHFP`.
        options = [.allowBluetooth, .defaultToSpeaker]
        #endif
        let categoryOptions = prefersSpeakerOutput ? options : options.subtracting(.defaultToSpeaker)
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: categoryOptions)
        try session.setPreferredSampleRate(config.sampleRate)
        try session.setActive(true)
        try session.overrideOutputAudioPort(prefersSpeakerOutput ? .speaker : .none)
        #else
        _ = needsInput
        #endif
    }

    private func installInputTapIfNeeded() throws {
        guard !isCaptureRunning else { return }
        guard let outputFormat else { return }
        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        log(.debug, "input format sampleRate=\(inputFormat.sampleRate) channels=\(inputFormat.channelCount)")
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            throw TS3Error.audioInputUnavailable
        }
        if inputFormat.sampleRate != config.sampleRate || inputFormat.channelCount != config.channels {
            converter = AVAudioConverter(from: inputFormat, to: outputFormat)
            log(.debug, "input converter enabled to sampleRate=\(config.sampleRate) channels=\(config.channels)")
        } else {
            converter = nil
            log(.debug, "input converter not needed")
        }

        inputNode.installTap(onBus: 0, bufferSize: config.frameSize, format: inputFormat) { [weak self] buffer, _ in
            self?.processInput(buffer: buffer, inputFormat: inputFormat, targetFormat: outputFormat)
        }
        log(.debug, "input tap installed")
    }

    private func startCaptureAttempt() throws {
        if engine.isRunning {
            engine.stop()
        }
        try configureSession(needsInput: true)
        try installInputTapIfNeeded()
        rebuildPlaybackGraph()
        try startEngineIfNeeded()
        isPlaybackRunning = true
        isCaptureRunning = true
        log(.info, "capture started")
    }

    private func cleanupCaptureStartFailure(restorePlayback: Bool) {
        engine.inputNode.removeTap(onBus: 0)
        converter = nil
        captureBuffer.removeAll()
        isCaptureRunning = false

        if restorePlayback {
            try? configureSession(needsInput: false)
            rebuildPlaybackGraph()
            try? startEngineIfNeeded()
            isPlaybackRunning = engine.isRunning
        } else {
            if engine.isRunning {
                engine.stop()
            }
            isPlaybackRunning = false
        }
    }

    private func recreateEngine(reason: String) {
        log(.debug, "recreating audio engine: \(reason)")
        if engine.isRunning {
            engine.stop()
        }

        for state in playbackStates.values {
            state.playerNode.stop()
            state.playerNode.reset()
        }

        engine = AVAudioEngine()
        converter = nil
        captureBuffer.removeAll()
        encodedPacketCount = 0
        droppedInputBufferCount = 0
        isPlaybackRunning = false
        isCaptureRunning = false

        if !playbackStates.isEmpty {
            rebuildPlaybackGraph()
        }
    }

    private func shouldRetryCaptureStart(after error: Error) -> Bool {
        #if targetEnvironment(macCatalyst) || os(macOS)
        if case TS3Error.audioInputUnavailable = error {
            return true
        }

        let nsError = error as NSError
        return nsError.code == Self.badAudioDeviceErrorCode
        #else
        _ = error
        return false
        #endif
    }

    private func captureStartError(from error: Error) -> Error {
        if case TS3Error.audioInputUnavailable = error {
            return error
        }

        let nsError = error as NSError
        if nsError.code == Self.badAudioDeviceErrorCode {
            return TS3Error.audioInputUnavailable
        }

        return error
    }

    private func processInput(buffer: AVAudioPCMBuffer, inputFormat: AVAudioFormat, targetFormat: AVAudioFormat) {
        let pcmBuffer: AVAudioPCMBuffer
        if let converter = converter {
            let ratio = targetFormat.sampleRate / inputFormat.sampleRate
            let outputCapacity = max(
                AVAudioFrameCount(ceil(Double(buffer.frameLength) * ratio)) + 16,
                config.frameSize
            )
            guard let converted = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputCapacity) else {
                return
            }
            var error: NSError?
            var didProvideInput = false
            converter.convert(to: converted, error: &error) { _, outStatus in
                if didProvideInput {
                    outStatus.pointee = .noDataNow
                    return nil
                }

                didProvideInput = true
                outStatus.pointee = .haveData
                return buffer
            }
            if let error {
                logDroppedInputBuffer("input conversion failed: \(error.localizedDescription)")
                return
            }
            if converted.frameLength == 0 {
                logDroppedInputBuffer("input conversion produced 0 frames")
                return
            }
            pcmBuffer = converted
        } else {
            pcmBuffer = buffer
        }

        guard let channelData = pcmBuffer.floatChannelData else {
            logDroppedInputBuffer("input buffer has no float channel data")
            return
        }
        let channel = channelData[0]
        let frames = Int(pcmBuffer.frameLength)
        guard frames > 0 else {
            logDroppedInputBuffer("input buffer has 0 frames")
            return
        }
        captureBuffer.append(contentsOf: UnsafeBufferPointer(start: channel, count: frames))

        while captureBuffer.count >= Int(config.frameSize) {
            let frame = processedFrame(Array(captureBuffer.prefix(Int(config.frameSize))))
            captureBuffer.removeFirst(Int(config.frameSize))
            guard shouldTransmit(frame: frame) else { continue }
            do {
                let packet = try encoder.encode(pcm: frame)
                encodedPacketCount += 1
                if encodedPacketCount == 1 || encodedPacketCount % 50 == 0 {
                    log(.debug, "encoded microphone packet count=\(encodedPacketCount) bytes=\(packet.count)")
                }
                onEncodedPacket?(packet)
            } catch {
                logDroppedInputBuffer("opus encode failed: \(error.localizedDescription)")
            }
        }
    }

    private func processedFrame(_ frame: [Float]) -> [Float] {
        guard inputGain != 1 else { return frame }
        return frame.map { min(max($0 * inputGain, -1), 1) }
    }

    private func shouldTransmit(frame: [Float]) -> Bool {
        guard transmitMode == .voiceActivation else { return true }
        let rms = sqrt(frame.reduce(Float(0)) { $0 + ($1 * $1) } / Float(max(frame.count, 1)))
        let isVoiceActive = rms >= voiceActivationThreshold
        if wasVoiceActive && !isVoiceActive {
            onEncodedPacket?(Data())
        }
        wasVoiceActive = isVoiceActive
        return isVoiceActive
    }

    private func logDroppedInputBuffer(_ reason: String) {
        droppedInputBufferCount += 1
        if droppedInputBufferCount == 1 || droppedInputBufferCount % 50 == 0 {
            log(.warning, "dropped microphone input buffer count=\(droppedInputBufferCount): \(reason)")
        }
    }

    private func playbackState(for source: PlaybackSource, sessionMarker: UInt8?) throws -> PlaybackState {
        guard let outputFormat else {
            throw TS3Error.notImplemented
        }

        if var state = playbackStates[source] {
            if shouldResetDecoder(current: state.sessionMarker, incoming: sessionMarker) {
                state.decoder = try makeDecoder()
            }
            if let sessionMarker {
                state.sessionMarker = sessionMarker
            }
            if !isPlayerNodeConnected(state.playerNode) {
                try updatePlaybackGraph {
                    detachPlayerNodeIfNeeded(state.playerNode)
                    state.playerNode = makePlayerNode(format: outputFormat)
                }
            }
            return state
        }

        if !isPlaybackRunning {
            try preparePlayback()
        }

        let playerNode = try updatePlaybackGraph {
            makePlayerNode(format: outputFormat)
        }
        isPlaybackRunning = true

        return PlaybackState(
            playerNode: playerNode,
            decoder: try makeDecoder(),
            sessionMarker: sessionMarker
        )
    }

    private func endPlayback(for source: PlaybackSource) {
        guard let state = playbackStates.removeValue(forKey: source) else { return }
        detachPlayerNodeIfNeeded(state.playerNode)
        stopEngineIfIdle()
    }

    private func stopEngineIfIdle() {
        guard !isCaptureRunning else { return }
        guard playbackStates.isEmpty else { return }
        if engine.isRunning {
            engine.stop()
        }
        isPlaybackRunning = false
    }

    private func shouldResetDecoder(current: UInt8?, incoming: UInt8?) -> Bool {
        guard let current, let incoming else { return false }
        return current != incoming
    }

    private func rebuildPlaybackGraph() {
        guard let outputFormat else { return }
        var rebuiltStates: [PlaybackSource: PlaybackState] = [:]
        rebuiltStates.reserveCapacity(playbackStates.count)

        for (source, var state) in playbackStates {
            detachPlayerNodeIfNeeded(state.playerNode)
            state.playerNode = makePlayerNode(format: outputFormat)
            rebuiltStates[source] = state
        }

        playbackStates = rebuiltStates
    }

    private func startEngineIfNeeded() throws {
        engine.prepare()
        if !engine.isRunning {
            try engine.start()
            log(.debug, "audio engine started")
        }
    }

    private func updatePlaybackGraph<T>(_ change: () throws -> T) throws -> T {
        if engine.isRunning {
            engine.stop()
        }
        let result = try change()
        try startEngineIfNeeded()
        return result
    }

    private func makePlayerNode(format: AVAudioFormat) -> AVAudioPlayerNode {
        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        return playerNode
    }

    private func isPlayerNodeConnected(_ playerNode: AVAudioPlayerNode) -> Bool {
        let attached = engine.attachedNodes.contains { $0 === playerNode }
        guard attached else { return false }
        return !engine.outputConnectionPoints(for: playerNode, outputBus: 0).isEmpty
    }

    private func detachPlayerNodeIfNeeded(_ playerNode: AVAudioPlayerNode) {
        playerNode.stop()
        playerNode.reset()
        if engine.attachedNodes.contains(where: { $0 === playerNode }) {
            engine.detach(playerNode)
        }
    }

    private func makeDecoder() throws -> TS3OpusDecoder {
        try TS3OpusFactory.makeDecoder(sampleRate: Int32(config.sampleRate), channels: Int32(config.channels))
    }

    private func log(_ level: TS3LogLevel, _ message: String) {
        onLog?(level, message)
    }

    private func play(samples: [Float], from clientId: UInt16, on playerNode: AVAudioPlayerNode) {
        guard let outputFormat else { return }
        guard !mutedPlaybackSources.contains(clientId) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: AVAudioFrameCount(samples.count)) else {
            return
        }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        let gain = sourcePlaybackGains[clientId] ?? 1
        if let channelData = buffer.floatChannelData {
            let channel = channelData[0]
            for i in 0..<samples.count {
                let scaled = samples[i] * playbackVolume * gain
                channel[i] = min(max(scaled, -1), 1)
            }
        }
        guard engine.isRunning else { return }
        guard isPlayerNodeConnected(playerNode) else { return }
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
}

#if canImport(Opus)
import Opus

final class OpusEncoderWrapper: TS3OpusEncoder {
    private var encoder: OpaquePointer?
    private let maxPacketSize = 1275

    init(sampleRate: Int32, channels: Int32, application: Int32) throws {
        var error: Int32 = 0
        encoder = opus_encoder_create(sampleRate, channels, application, &error)
        if error != OPUS_OK {
            throw TS3Error.cryptoFailed
        }
    }

    deinit {
        if let encoder {
            opus_encoder_destroy(encoder)
        }
    }

    func encode(pcm: [Float]) throws -> Data {
        guard let encoder else { throw TS3Error.cryptoFailed }
        var output = [UInt8](repeating: 0, count: maxPacketSize)
        let frameSize = Int32(pcm.count)
        let len = opus_encode_float(encoder, pcm, frameSize, &output, Int32(maxPacketSize))
        if len < 0 {
            throw TS3Error.cryptoFailed
        }
        return Data(output.prefix(Int(len)))
    }
}

final class OpusDecoderWrapper: TS3OpusDecoder {
    private var decoder: OpaquePointer?

    init(sampleRate: Int32, channels: Int32) throws {
        var error: Int32 = 0
        decoder = opus_decoder_create(sampleRate, channels, &error)
        if error != OPUS_OK {
            throw TS3Error.cryptoFailed
        }
    }

    deinit {
        if let decoder {
            opus_decoder_destroy(decoder)
        }
    }

    func decode(packet: Data) throws -> [Float] {
        guard let decoder else { throw TS3Error.cryptoFailed }
        var output = [Float](repeating: 0, count: 5760)
        let frameSize = opus_decode_float(decoder, [UInt8](packet), Int32(packet.count), &output, Int32(output.count), 0)
        if frameSize < 0 {
            throw TS3Error.cryptoFailed
        }
        return Array(output.prefix(Int(frameSize)))
    }
}
#endif
