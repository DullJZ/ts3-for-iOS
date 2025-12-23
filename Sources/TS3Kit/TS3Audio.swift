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
    private let playerNode = AVAudioPlayerNode()
    private var converter: AVAudioConverter?
    private var captureBuffer: [Float] = []

    private let encoder: TS3OpusEncoder
    private let decoder: TS3OpusDecoder

    var onEncodedPacket: ((Data) -> Void)?

    private var isRunning = false

    init(config: Config) throws {
        self.config = config
        self.encoder = try TS3OpusFactory.makeEncoder(sampleRate: Int32(config.sampleRate), channels: Int32(config.channels), application: config.opusApplication)
        self.decoder = try TS3OpusFactory.makeDecoder(sampleRate: Int32(config.sampleRate), channels: Int32(config.channels))
    }

    func start() throws {
        if isRunning { return }
        try configureSession()
        setupEngine()
        engine.prepare()
        try engine.start()
        playerNode.play()
        isRunning = true
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        playerNode.stop()
        engine.stop()
        isRunning = false
    }

    func handleIncoming(packet: Data) {
        guard !packet.isEmpty else { return }
        do {
            let samples = try decoder.decode(packet: packet)
            play(samples: samples)
        } catch {
            // ignore
        }
    }

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
        try session.setPreferredSampleRate(config.sampleRate)
        try session.setActive(true)
    }

    private func setupEngine() {
        engine.attach(playerNode)
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: config.sampleRate,
                                         channels: config.channels,
                                         interleaved: false)!
        engine.connect(playerNode, to: engine.mainMixerNode, format: outputFormat)

        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        if inputFormat.sampleRate != config.sampleRate || inputFormat.channelCount != config.channels {
            converter = AVAudioConverter(from: inputFormat, to: outputFormat)
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

    private func play(samples: [Float]) {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: config.sampleRate,
                                         channels: config.channels,
                                         interleaved: false) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else {
            return
        }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        if let channelData = buffer.floatChannelData {
            let channel = channelData[0]
            for i in 0..<samples.count {
                channel[i] = samples[i]
            }
        }
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
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
