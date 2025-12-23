import Foundation

enum TS3String {
    static func escape(_ string: String) -> String {
        var result = ""
        result.reserveCapacity(string.count)

        for char in string {
            switch char {
            case "\\": result.append("\\\\")
            case "/": result.append("\\/")
            case " ": result.append("\\s")
            case "|": result.append("\\p")
            case "\u{000C}": result.append("\\f")
            case "\n": result.append("\\n")
            case "\r": result.append("\\r")
            case "\t": result.append("\\t")
            default:
                result.append(char)
            }
        }

        return result
    }

    static func unescape(_ string: String) throws -> String {
        var result = ""
        result.reserveCapacity(string.count)

        var iterator = string.makeIterator()
        while let char = iterator.next() {
            if char == "\\" {
                guard let next = iterator.next() else {
                    throw TS3Error.invalidEscape
                }

                switch next {
                case "t": result.append("\t")
                case "r": result.append("\r")
                case "n": result.append("\n")
                case "f": result.append("\u{000C}")
                case "p": result.append("|")
                case "s": result.append(" ")
                case "/": result.append("/")
                case "\\": result.append("\\")
                default:
                    throw TS3Error.invalidEscape
                }
            } else {
                result.append(char)
            }
        }

        return result
    }
}
