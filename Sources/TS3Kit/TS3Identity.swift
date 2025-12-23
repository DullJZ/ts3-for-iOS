import Foundation
import CryptoKit
import CryptoSwift

struct TS3Uid {
    let bytes: [UInt8]

    func toBase64() -> String {
        Data(bytes).base64EncodedString()
    }
}

struct TS3Identity {
    let privateKeyBytes: [UInt8]
    let publicKeyBytes: [UInt8]
    let publicKeyString: String
    let uid: TS3Uid

    private(set) var keyOffset: Int
    private(set) var lastCheckedKeyOffset: Int

    init(privateKeyBytes: [UInt8], keyOffset: Int = 0) throws {
        guard privateKeyBytes.count == 32 else {
            throw TS3Error.invalidKey
        }

        let signingKey = try P256.Signing.PrivateKey(rawRepresentation: Data(privateKeyBytes))
        let publicKeyData = signingKey.publicKey.x963Representation
        let publicKeyBytes = [UInt8](publicKeyData)
        guard publicKeyBytes.count == 65 else {
            throw TS3Error.invalidKey
        }

        let x = Array(publicKeyBytes[1..<33])
        let y = Array(publicKeyBytes[33..<65])
        let der = TS3Crypto.encodePublicKey(x: x, y: y)
        let pubString = Data(der).base64EncodedString()
        let uidBytes = TS3Crypto.hash128([UInt8](pubString.utf8))

        self.privateKeyBytes = privateKeyBytes
        self.publicKeyBytes = publicKeyBytes
        self.publicKeyString = pubString
        self.uid = TS3Uid(bytes: uidBytes)
        self.keyOffset = keyOffset
        self.lastCheckedKeyOffset = keyOffset
    }

    static func generate(securityLevel: Int) throws -> TS3Identity {
        var privateKey = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, privateKey.count, &privateKey)
        var identity = try TS3Identity(privateKeyBytes: privateKey)
        identity.improveSecurity(target: securityLevel)
        return identity
    }

    mutating func improveSecurity(target: Int) {
        let pubKeyBytes = [UInt8](publicKeyString.utf8)
        var hashBuffer = [UInt8](repeating: 0, count: pubKeyBytes.count + 20)
        hashBuffer.replaceSubrange(0..<pubKeyBytes.count, with: pubKeyBytes)

        lastCheckedKeyOffset = max(keyOffset, lastCheckedKeyOffset)
        var best = Self.securityLevel(hashBuffer: &hashBuffer, pubKeyLen: pubKeyBytes.count, offset: keyOffset)

        while true {
            if best >= target { return }
            let current = Self.securityLevel(hashBuffer: &hashBuffer, pubKeyLen: pubKeyBytes.count, offset: lastCheckedKeyOffset)
            if current > best {
                keyOffset = lastCheckedKeyOffset
                best = current
            }
            lastCheckedKeyOffset += 1
        }
    }

    func sign(data: [UInt8]) throws -> [UInt8] {
        let signingKey = try P256.Signing.PrivateKey(rawRepresentation: Data(privateKeyBytes))
        let signature = try signingKey.signature(for: Data(data))
        return [UInt8](signature.derRepresentation)
    }

    func sharedSecret(with omega: [UInt8]) throws -> [UInt8] {
        let publicKey = try TS3Crypto.decodePublicKey(omega)
        let keyAgreement = try P256.KeyAgreement.PrivateKey(rawRepresentation: Data(privateKeyBytes))
        let secret = try keyAgreement.sharedSecretFromKeyAgreement(with: publicKey)
        let secretBytes = secret.withUnsafeBytes { Array($0) }
        return TS3Crypto.sharedSecretHash(from: secretBytes)
    }

    func securityLevel() -> Int {
        let pubKeyBytes = [UInt8](publicKeyString.utf8)
        var hashBuffer = [UInt8](repeating: 0, count: pubKeyBytes.count + 20)
        hashBuffer.replaceSubrange(0..<pubKeyBytes.count, with: pubKeyBytes)
        return Self.securityLevel(hashBuffer: &hashBuffer, pubKeyLen: pubKeyBytes.count, offset: keyOffset)
    }

    private static func securityLevel(hashBuffer: inout [UInt8], pubKeyLen: Int, offset: Int) -> Int {
        var num = offset
        var numBytes: [UInt8] = []
        repeat {
            numBytes.append(UInt8(48 + (num % 10)))
            num /= 10
        } while num > 0

        for i in 0..<numBytes.count {
            hashBuffer[pubKeyLen + i] = numBytes[numBytes.count - (i + 1)]
        }

        let hash = TS3Crypto.hash128(Array(hashBuffer[0..<(pubKeyLen + numBytes.count)]))
        return Self.leadingZeroBits(hash)
    }

    private static func leadingZeroBits(_ data: [UInt8]) -> Int {
        var count = 0
        var index = 0
        while index < data.count, data[index] == 0 {
            count += 8
            index += 1
        }
        if index < data.count {
            for bit in 0..<8 {
                if (data[index] & (1 << bit)) == 0 {
                    count += 1
                } else {
                    break
                }
            }
        }
        return count
    }
}
