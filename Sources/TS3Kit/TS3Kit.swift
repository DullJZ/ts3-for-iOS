import Foundation

public struct TS3ClientConfig {
    public let host: String
    public let port: Int
    public let nickname: String
    public let serverPassword: String?

    public init(host: String, port: Int, nickname: String, serverPassword: String?) {
        self.host = host
        self.port = port
        self.nickname = nickname
        self.serverPassword = serverPassword
    }
}

public struct TS3Channel: Identifiable {
    public let id: Int
    public let name: String
    public let topic: String?

    public init(id: Int, name: String, topic: String?) {
        self.id = id
        self.name = name
        self.topic = topic
    }
}

public protocol TS3ClientDelegate: AnyObject {
    func ts3ClientDidConnect(_ client: TS3Client)
    func ts3Client(_ client: TS3Client, didDisconnectWith error: Error?)
    func ts3Client(_ client: TS3Client, didUpdateChannels channels: [TS3Channel])
}

public enum TS3Error: Error {
    case notImplemented
    case invalidEscape
    case ambiguousCommand
    case derDecodeFailed
    case invalidBeta
    case invalidInitStep
    case invalidCommand
    case invalidIdentity
    case invalidKey
    case invalidLicense
    case invalidMac
    case cryptoFailed
    case serverError(message: String)
    case packetTooLarge
    case invalidState
    case timeout
    case disconnected
    case compressionUnsupported
    case decompressionTooLarge
}

public enum TS3LogLevel: String {
    case debug
    case info
    case warning
    case error
}

public struct TS3LogEntry: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let level: TS3LogLevel
    public let message: String

    public init(timestamp: Date, level: TS3LogLevel, message: String) {
        self.timestamp = timestamp
        self.level = level
        self.message = message
    }
}
