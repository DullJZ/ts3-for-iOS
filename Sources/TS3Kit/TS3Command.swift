import Foundation

protocol TS3CommandParameter {
    var name: String { get }
    func build() -> String
}

struct TS3CommandOption: TS3CommandParameter {
    let name: String

    func build() -> String {
        "-" + name
    }
}

struct TS3CommandSingleParameter: TS3CommandParameter {
    let name: String
    let value: String?

    func build() -> String {
        if let value {
            return "\(name)=\(TS3String.escape(value))"
        }
        return name
    }
}

protocol TS3Command {
    var name: String { get }
    var parameters: [TS3CommandParameter] { get }
    func build() -> String
}

struct TS3SingleCommand: TS3Command {
    let name: String
    var parameters: [TS3CommandParameter]

    init(name: String, parameters: [TS3CommandParameter] = []) {
        self.name = name
        self.parameters = parameters
    }

    func build() -> String {
        var parts: [String] = []
        if !name.isEmpty {
            parts.append(name)
        }
        parts.append(contentsOf: parameters.map { $0.build() })
        return parts.joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }

    func has(_ name: String) -> Bool {
        parameters.contains { $0.name == name }
    }

    func get(_ name: String) -> TS3CommandSingleParameter? {
        parameters.compactMap { $0 as? TS3CommandSingleParameter }.first { $0.name == name }
    }

    func toMap() -> [String: String] {
        var map: [String: String] = [:]
        for param in parameters {
            if let param = param as? TS3CommandSingleParameter,
               let value = param.value {
                map[param.name] = value
            }
        }
        return map
    }
}

struct TS3MultiCommand: TS3Command {
    let name: String
    let commands: [TS3SingleCommand]
    var parameters: [TS3CommandParameter]

    init(name: String, commands: [TS3SingleCommand], parameters: [TS3CommandParameter] = []) {
        self.name = name
        self.commands = commands
        self.parameters = parameters
    }

    func build() -> String {
        let staticCommand = TS3SingleCommand(name: name, parameters: parameters)
        var result = staticCommand.build()

        if commands.isEmpty {
            return result
        }

        let parts = commands.enumerated().map { index, cmd -> String in
            let combined = cmd.parameters.map { $0.build() }.joined(separator: " ")
            if index == 0 {
                return combined
            }
            return combined
        }

        if !parts.isEmpty {
            let suffix = parts.joined(separator: "|")
            if !suffix.isEmpty {
                result = (result + " " + suffix).trimmingCharacters(in: .whitespaces)
            }
        }

        return result
    }

    func simplify() -> [TS3SingleCommand] {
        commands
    }

    func simplifyOne() throws -> TS3SingleCommand {
        if commands.count != 1 {
            throw TS3Error.ambiguousCommand
        }
        return commands[0]
    }

    static func parse(_ text: String) throws -> TS3MultiCommand {
        let labelAndRest = text.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        var label = labelAndRest.first.map { String($0) } ?? ""
        var rest = labelAndRest.count > 1 ? String(labelAndRest[1]) : ""

        if label.contains("=") {
            rest = text
            label = ""
        }

        let commandParts = rest.isEmpty ? [""] : rest.split(separator: "|").map(String.init)
        var singleCommands: [TS3SingleCommand] = []

        for commandText in commandParts {
            let pieces = commandText.split(separator: " ").map(String.init)
            var params: [TS3CommandParameter] = []

            for raw in pieces {
                let trimmed = raw.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty { continue }

                if trimmed.hasPrefix("-") {
                    let name = String(trimmed.dropFirst())
                    params.append(TS3CommandOption(name: name))
                } else {
                    let parts = trimmed.split(separator: "=", maxSplits: 1).map(String.init)
                    let key = parts[0].lowercased()
                    let value = parts.count > 1 ? try TS3String.unescape(parts[1]) : nil
                    params.append(TS3CommandSingleParameter(name: key, value: value))
                }
            }

            var command = TS3SingleCommand(name: label.lowercased(), parameters: params)
            if let first = singleCommands.first {
                for param in first.parameters where !command.has(param.name) {
                    command.parameters.append(param)
                }
            }
            singleCommands.append(command)
        }

        if singleCommands.isEmpty {
            singleCommands.append(TS3SingleCommand(name: label.lowercased()))
        }

        return TS3MultiCommand(name: label.lowercased(), commands: singleCommands)
    }
}
