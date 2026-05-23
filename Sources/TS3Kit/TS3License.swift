import Foundation

enum TS3LicenseUseType: UInt8 {
    case intermediate = 0
    case server = 2
    case ephemeral = 32
}

protocol TS3LicenseUse {
    var useType: TS3LicenseUseType { get }
    func read(from buffer: inout TS3ByteBuffer)
}

struct TS3ServerLicenseUse: TS3LicenseUse {
    let useType: TS3LicenseUseType = .server
    var type: UInt8 = 0
    var unknown: [UInt8] = [UInt8](repeating: 0, count: 4)
    var issuer: String = ""

    mutating func read(from buffer: inout TS3ByteBuffer) {
        type = buffer.readUInt8()
        unknown = Array(buffer.readBytes(count: 4))
        issuer = TS3License.readNullTerminatedString(buffer: &buffer)
    }
}

struct TS3IntermediateLicenseUse: TS3LicenseUse {
    let useType: TS3LicenseUseType = .intermediate
    var unknown: [UInt8] = [UInt8](repeating: 0, count: 4)
    var issuer: String = ""

    mutating func read(from buffer: inout TS3ByteBuffer) {
        unknown = Array(buffer.readBytes(count: 4))
        issuer = TS3License.readNullTerminatedString(buffer: &buffer)
    }
}

struct TS3EphemeralLicenseUse: TS3LicenseUse {
    let useType: TS3LicenseUseType = .ephemeral
    mutating func read(from buffer: inout TS3ByteBuffer) {
        // no fields
    }
}

struct TS3License {
    static let rootKey: [UInt8] = [
        0xcd, 0x0d, 0xe2, 0xae, 0xd4, 0x63, 0x45, 0x50, 0x9a,
        0x7e, 0x3c, 0xfd, 0x8f, 0x68, 0xb3, 0xdc, 0x75, 0x55, 0xb2,
        0x9d, 0xcc, 0xec, 0x73, 0xcd, 0x18, 0x75, 0x0f, 0x99,
        0x38, 0x12, 0x40, 0x8a
    ]

    var publicKey: [UInt8] = [UInt8](repeating: 0, count: 32)
    var licenseBlockType: UInt8 = 0
    var start: UInt32 = 0
    var end: UInt32 = 0
    var use: TS3LicenseUse
    var computedHash: [UInt8]

    init(use: TS3LicenseUse, computedHash: [UInt8]) {
        self.use = use
        self.computedHash = computedHash
    }

    static func readLicenses(data: [UInt8]) throws -> [TS3License] {
        var buffer = TS3ByteBuffer(data: Data(data))
        let version = buffer.readUInt8()
        guard version == 0x01 else {
            throw TS3Error.invalidLicense
        }

        var licenses: [TS3License] = []
        while buffer.remaining > 0 {
            let startIndex = buffer.readerIndex

            let keyType = buffer.readUInt8()
            guard keyType == 0x00 else {
                throw TS3Error.invalidLicense
            }

            let publicKey = Array(buffer.readBytes(count: 32))
            let licenseBlockType = buffer.readUInt8()
            let start = buffer.readUInt32() & 0x00FFFFFF
            let end = buffer.readUInt32() & 0x00FFFFFF

            let useType = TS3LicenseUseType(rawValue: licenseBlockType) ?? .ephemeral
            var use: TS3LicenseUse
            switch useType {
            case .server:
                var serverUse = TS3ServerLicenseUse()
                serverUse.read(from: &buffer)
                use = serverUse
            case .intermediate:
                var intermediate = TS3IntermediateLicenseUse()
                intermediate.read(from: &buffer)
                use = intermediate
            case .ephemeral:
                var ephemeral = TS3EphemeralLicenseUse()
                ephemeral.read(from: &buffer)
                use = ephemeral
            }

            let endIndex = buffer.readerIndex
            let len = endIndex - startIndex
            let hashable = Array(data[(startIndex + 1)..<startIndex + len])
            let licenseHash = TS3Crypto.hash512(hashable)
            let computedHash = Array(licenseHash.prefix(32))

            var license = TS3License(use: use, computedHash: computedHash)
            license.publicKey = publicKey
            license.licenseBlockType = licenseBlockType
            license.start = start
            license.end = end

            licenses.append(license)
        }

        return licenses
    }

    static func deriveKey(_ blocks: [TS3License]) throws -> [UInt8] {
        var round = rootKey
        for block in blocks {
            round = try block.deriveKey(parent: round)
        }
        return round
    }

    func deriveKey(parent: [UInt8]) throws -> [UInt8] {
        var hash = computedHash
        TS3Ed25519.clamp(&hash)

        var pubKey = publicKey
        pubKey[31] ^= 0x80
        var parKey = parent
        parKey[31] ^= 0x80

        let res = try TS3Ed25519.scalarMult(privateKey: hash, publicKey: pubKey)
        let sum = try TS3Ed25519.add(res, parKey)
        var finalKey = sum
        finalKey[31] ^= 0x80
        return finalKey
    }

    static func readNullTerminatedString(buffer: inout TS3ByteBuffer) -> String {
        var bytes: [UInt8] = []
        while buffer.remaining > 0 {
            let c = buffer.readUInt8()
            if c == 0x00 {
                break
            }
            bytes.append(c)
        }
        return String(data: Data(bytes), encoding: .utf8) ?? ""
    }
}
