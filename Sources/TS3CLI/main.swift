import Foundation
import TS3Kit

// Helper to keep the run loop alive
var keepRunning = true

// Simple logger implementation
struct CLILogger {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    static let logHandler: (TS3LogEntry) -> Void = { entry in
        let time = formatter.string(from: entry.timestamp)
        let level = String(describing: entry.level).uppercased()
        
        switch entry.level {
        case .error:
            // Use ANSI red for error
            print("\u{001B}[0;31m\(time) [\(level)] \(entry.message)\u{001B}[0m")
        case .warning:
            // Use ANSI yellow for warning
            print("\u{001B}[0;33m\(time) [\(level)] \(entry.message)\u{001B}[0m")
        case .debug:
            // Use ANSI gray for debug
            print("\u{001B}[0;90m\(time) [\(level)] \(entry.message)\u{001B}[0m")
        default:
            print("\(time) [\(level)] \(entry.message)")
        }
    }
}

@main
struct TS3CLI {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())

        guard args.count >= 2 else {
            print("Usage: ts3-cli <host> <port> [nickname] [--mic-seconds <seconds>]")
            print("Example: ts3-cli 120.24.89.226 9987 MyTS3Bot --mic-seconds 2")
            exit(1)
        }

        var positional: [String] = []
        var microphoneSeconds: Double?
        var index = 0

        while index < args.count {
            let argument = args[index]
            switch argument {
            case "--mic-seconds":
                guard index + 1 < args.count,
                      let value = Double(args[index + 1]),
                      value > 0 else {
                    print("Error: --mic-seconds expects a positive number")
                    exit(1)
                }
                microphoneSeconds = value
                index += 2
            default:
                positional.append(argument)
                index += 1
            }
        }

        guard positional.count >= 2 else {
            print("Usage: ts3-cli <host> <port> [nickname] [--mic-seconds <seconds>]")
            exit(1)
        }

        let host = positional[0]
        guard let port = UInt16(positional[1]) else {
            print("Error: Invalid port number")
            exit(1)
        }

        let nickname = positional.count > 2 ? positional[2] : "TS3CLI_User"

        print("Starting TS3 Client...")
        print("Host: \(host)")
        print("Port: \(port)")
        print("Nickname: \(nickname)")
        if let microphoneSeconds {
            print("Microphone test: \(microphoneSeconds)s")
        }

        let config = TS3ClientConfig(host: host, port: Int(port), nickname: nickname, serverPassword: nil)
        let client = TS3Client(config: config)

        client.logHandler = CLILogger.logHandler

        do {
            try await client.connect()

            if let microphoneSeconds {
                print("Starting microphone capture...")
                try client.startMicrophone()
                try await Task.sleep(nanoseconds: UInt64(microphoneSeconds * 1_000_000_000))
                client.stopMicrophone()
                client.disconnect(reason: "cli-microphone-test")
                return
            }

            // Keep running until interrupted
            // In a real CLI app, we might handle SIGINT to exit gracefully
            while keepRunning {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
        } catch {
            print("Connection failed: \(error)")
            exit(1)
        }
    }
}
