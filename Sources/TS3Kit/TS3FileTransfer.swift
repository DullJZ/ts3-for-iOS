import Foundation
import Network

public enum TS3FileTransfer {
    /// Downloads a channel file using negotiated file transfer parameters.
    public static func download(
        parameters: TS3FileTransferParameters,
        to destination: URL,
        progress: (@Sendable (Int64, Int64?) -> Void)? = nil
    ) async throws {
        let socket = TS3FileTransferSocket(parameters: parameters)
        try await withTaskCancellationHandler {
            defer {
                socket.cancel()
            }
            try Task.checkCancellation()
            try await socket.connect()
            try Task.checkCancellation()
            try await socket.sendKey()
            try Task.checkCancellation()
            try await socket.download(to: destination, progress: progress)
        } onCancel: {
            socket.cancel()
        }
    }

    /// Uploads a local file using negotiated file transfer parameters.
    public static func upload(
        parameters: TS3FileTransferParameters,
        from source: URL,
        progress: (@Sendable (Int64, Int64?) -> Void)? = nil
    ) async throws {
        let socket = TS3FileTransferSocket(parameters: parameters)
        try await withTaskCancellationHandler {
            defer {
                socket.cancel()
            }
            try Task.checkCancellation()
            try await socket.connect()
            try Task.checkCancellation()
            try await socket.sendKey()
            try Task.checkCancellation()
            try await socket.upload(from: source, progress: progress)
        } onCancel: {
            socket.cancel()
        }
    }
}

private final class TS3FileTransferSocket {
    private let parameters: TS3FileTransferParameters
    private let connection: NWConnection
    private let queue = DispatchQueue(label: "ts3.file-transfer")

    init(parameters: TS3FileTransferParameters) {
        self.parameters = parameters
        let host = NWEndpoint.Host(parameters.host)
        let port = NWEndpoint.Port(rawValue: UInt16(parameters.port)) ?? 30033
        connection = NWConnection(host: host, port: port, using: .tcp)
    }

    func connect() async throws {
        try await withCheckedThrowingContinuation { continuation in
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    self.connection.stateUpdateHandler = nil
                    continuation.resume()
                case .failed(let error):
                    self.connection.stateUpdateHandler = nil
                    continuation.resume(throwing: error)
                case .cancelled:
                    self.connection.stateUpdateHandler = nil
                    continuation.resume(throwing: TS3Error.disconnected)
                default:
                    break
                }
            }
            connection.start(queue: queue)
        }
    }

    func sendKey() async throws {
        guard let data = parameters.key.data(using: .utf8) else {
            throw TS3Error.fileTransferFailed
        }
        try await send(data)
    }

    func upload(
        from source: URL,
        progress: (@Sendable (Int64, Int64?) -> Void)?
    ) async throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: source.path)
        let expectedSize = (attributes[.size] as? NSNumber)?.int64Value
        let handle = try FileHandle(forReadingFrom: source)
        defer {
            try? handle.close()
        }

        var sent: Int64 = 0
        while true {
            try Task.checkCancellation()
            let chunk = try handle.read(upToCount: 64 * 1024) ?? Data()
            if chunk.isEmpty {
                break
            }
            try await send(chunk)
            sent += Int64(chunk.count)
            progress?(sent, expectedSize)
        }
    }

    func download(
        to destination: URL,
        progress: (@Sendable (Int64, Int64?) -> Void)?
    ) async throws {
        FileManager.default.createFile(atPath: destination.path, contents: nil)
        let handle = try FileHandle(forWritingTo: destination)
        defer {
            try? handle.close()
        }

        let expectedSize = parameters.size
        var received: Int64 = 0
        while expectedSize == nil || received < (expectedSize ?? 0) {
            try Task.checkCancellation()
            let remaining = expectedSize.map { max(1, min(Int($0 - received), 64 * 1024)) } ?? (64 * 1024)
            let chunk = try await receive(maximumLength: remaining)
            if chunk.isEmpty {
                break
            }
            try handle.write(contentsOf: chunk)
            received += Int64(chunk.count)
            progress?(received, expectedSize)
        }
    }

    func cancel() {
        connection.cancel()
    }

    private func send(_ data: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.send(content: data, completion: .contentProcessed { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }

    private func receive(maximumLength: Int) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            connection.receive(minimumIncompleteLength: 1, maximumLength: maximumLength) { data, _, isComplete, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data {
                    continuation.resume(returning: data)
                } else if isComplete {
                    continuation.resume(returning: Data())
                } else {
                    continuation.resume(throwing: TS3Error.fileTransferFailed)
                }
            }
        }
    }
}
