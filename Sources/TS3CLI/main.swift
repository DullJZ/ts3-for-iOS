import Foundation
import TS3Kit

// Helper to keep the run loop alive
var keepRunning = true

// Simple logger implementation
struct CLILogger {
    static let logHandler: (TS3LogEntry) -> Void = { entry in
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
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
        let args = CommandLine.arguments
        
        guard args.count >= 3 else {
            print("Usage: ts3-cli <host> <port> [nickname]")
            print("Example: ts3-cli 120.24.89.226 9987 MyTS3Bot")
            exit(1)
        }
        
        let host = args[1]
        guard let port = UInt16(args[2]) else {
            print("Error: Invalid port number")
            exit(1)
        }
        
        let nickname = args.count > 3 ? args[3] : "TS3CLI_User"
        
        print("Starting TS3 Client...")
        print("Host: \(host)")
        print("Port: \(port)")
        print("Nickname: \(nickname)")
        
        let config = TS3ClientConfig(host: host, port: Int(port), nickname: nickname, serverPassword: nil)
        let client = TS3Client(config: config)
        
        client.logHandler = CLILogger.logHandler
        
        do {
            try await client.connect()
            
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
