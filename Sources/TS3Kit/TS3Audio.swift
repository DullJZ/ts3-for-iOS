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
    struct Config {
        let sampleRate: Double
        let channels: AVAudioChannelCount
        let frameSize: AVAudioFrameCount
        let opusApplication: Int32

        static let voice = Config(sampleRate: 48_000, channels: 1, frameSize: 960, opusApplication: 2048)
    }

    private let config: Config
    private let engine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private var captureBuffer: [Float] = []
    private lazy var outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                                  sampleRate: config.sampleRate,
                                                  channels: config.channels,
                                                  interleaved: false)

    private let encoder: TS3OpusEncoder
    private var playbackStates: [PlaybackSource: PlaybackState] = [:]
    private var playbackVolume: Float = 1.0

    var onEncodedPacket: ((Data) -> Void)?
    var onLog: ((TS3LogLevel, String) -> Void)?

    private var isPlaybackRunning = false
    private var isCaptureRunning = false

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
        if engine.isRunning {
            engine.stop()
        }
        do {
            try configureSession(needsInput: true)
            installInputTapIfNeeded()
            rebuildPlaybackGraph()
            try startEngineIfNeeded()
            isPlaybackRunning = true
            isCaptureRunning = true
        } catch {
            engine.inputNode.removeTap(onBus: 0)
            converter = nil
            captureBuffer.removeAll()
            isCaptureRunning = false
            if shouldResumePlayback {
                try? configureSession(needsInput: false)
                rebuildPlaybackGraph()
                try? startEngineIfNeeded()
                isPlaybackRunning = engine.isRunning
            } else {
                isPlaybackRunning = false
            }
            throw error
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
            play(samples: samples, on: state.playerNode)
        } catch {
            let route = isWhisper ? "whisper" : "channel"
            log(.warning, "playback failed for \(route) source \(clientId): \(error.localizedDescription)")
        }
    }

    private func configureSession(needsInput: Bool) throws {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        let options: AVAudioSession.CategoryOptions = [.allowBluetoothHFP, .defaultToSpeaker]
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: options)
        try session.setPreferredSampleRate(config.sampleRate)
        try session.setActive(true)
        #endif
    }

    private func installInputTapIfNeeded() {
        guard !isCaptureRunning else { return }
        guard let outputFormat else { return }
        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        if inputFormat.sampleRate != config.sampleRate || inputFormat.channelCount != config.channels {
            converter = AVAudioConverter(from: inputFormat, to: outputFormat)
        } else {
            converter = nil
        }

        inputNode.installTap(onBus: 0, bufferSize: config.frameSize, format: inputFormat) { [weak self] buffer, _ in
            self?.processInput(buffer: buffer, inputFormat: inputFormat, targetFormat: outputFormat)
        }
    }

    private func processInput(buffer: AVAudioPCMBuffer, inputFormat: AVAudioFormat, targetFormat: AVAudioFormat) {
        let pcmBuffer: AVAudioPCMBuffer
        if let converter = converter {
            guard let converted = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: buffer.frameCapacity) else {
                return
            }
            var error: NSError?
            converter.convert(to: converted, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            if error != nil {
                return
            }
            pcmBuffer = converted
        } else {
            pcmBuffer = buffer
        }

        guard let channelData = pcmBuffer.floatChannelData else { return }
        let channel = channelData[0]
        let frames = Int(pcmBuffer.frameLength)
        captureBuffer.append(contentsOf: UnsafeBufferPointer(start: channel, count: frames))

        while captureBuffer.count >= Int(config.frameSize) {
            let frame = Array(captureBuffer.prefix(Int(config.frameSize)))
            captureBuffer.removeFirst(Int(config.frameSize))
            do {
                let packet = try encoder.encode(pcm: frame)
                onEncodedPacket?(packet)
            } catch {
                // ignore
            }
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

    private func play(samples: [Float], on playerNode: AVAudioPlayerNode) {
        guard let outputFormat else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: AVAudioFrameCount(samples.count)) else {
            return
        }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        if let channelData = buffer.floatChannelData {
            let channel = channelData[0]
            for i in 0..<samples.count {
                let scaled = samples[i] * playbackVolume
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
