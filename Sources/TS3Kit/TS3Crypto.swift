import Foundation
import CryptoKit
import CryptoSwift

struct TS3SecureChannelParameters {
    let fakeMac: [UInt8]
    let ivStruct: [UInt8]
}

enum TS3Crypto {
    static let initKey: [UInt8] = [
        0x63, 0x3A, 0x5C, 0x77, 0x69, 0x6E, 0x64, 0x6F,
        0x77, 0x73, 0x5C, 0x73, 0x79, 0x73, 0x74, 0x65
    ]

    static let initNonce: [UInt8] = [
        0x6D, 0x5C, 0x66, 0x69, 0x72, 0x65, 0x77, 0x61,
        0x6C, 0x6C, 0x33, 0x32, 0x2E, 0x63, 0x70, 0x6C
    ]

    static func hash128(_ data: [UInt8]) -> [UInt8] {
        Array(Insecure.SHA1.hash(data: Data(data)))
    }

    static func hash256(_ data: [UInt8]) -> [UInt8] {
        Array(SHA256.hash(data: Data(data)))
    }

    static func hash512(_ data: [UInt8]) -> [UInt8] {
        Array(SHA512.hash(data: Data(data)))
    }

    static func xor(_ a: [UInt8], aOffset: Int, _ b: [UInt8], bOffset: Int, length: Int) -> [UInt8] {
        var output = [UInt8](repeating: 0, count: length)
        for i in 0..<length {
            output[i] = a[aOffset + i] ^ b[bOffset + i]
        }
        return output
    }

    static func secureParameters(alpha: [UInt8], beta: [UInt8], sharedKey: [UInt8]) throws -> TS3SecureChannelParameters {
        guard beta.count == 10 || beta.count == 54 else {
            throw TS3Error.invalidBeta
        }

        var ivStruct = [UInt8](repeating: 0, count: 10 + beta.count)
        let part1 = xor(sharedKey, aOffset: 0, alpha, bOffset: 0, length: alpha.count)
        let part2 = xor(sharedKey, aOffset: 10, beta, bOffset: 0, length: beta.count)
        ivStruct.replaceSubrange(0..<alpha.count, with: part1)
        ivStruct.replaceSubrange(10..<(10 + beta.count), with: part2)

        let buffer = hash128(ivStruct)
        let fakeMac = Array(buffer.prefix(8))
        return TS3SecureChannelParameters(fakeMac: fakeMac, ivStruct: ivStruct)
    }

    static func cryptoInit(alpha: [UInt8], beta: [UInt8], omega: [UInt8], identity: TS3Identity) throws -> TS3SecureChannelParameters {
        guard beta.count == 10 || beta.count == 54 else {
            throw TS3Error.invalidBeta
        }
        let sharedKey = try identity.sharedSecret(with: omega)
        return try secureParameters(alpha: alpha, beta: beta, sharedKey: sharedKey)
    }

    static func cryptoInit2(license: [UInt8], alpha: [UInt8], beta: [UInt8], privateKey: [UInt8]) throws -> TS3SecureChannelParameters {
        let licenses = try TS3License.readLicenses(data: license)
        let key = try TS3License.deriveKey(licenses)
        let sharedSecret = try generateSharedSecret2(publicKey: key, privateKey: privateKey)
        return try secureParameters(alpha: alpha, beta: beta, sharedKey: sharedSecret)
    }

    static func generateSharedSecret2(publicKey: [UInt8], privateKey: [UInt8]) throws -> [UInt8] {
        var privateCopy = privateKey
        TS3Ed25519.clamp(&privateCopy)
        let shared = try TS3Ed25519.scalarMult(privateKey: privateCopy, publicKey: publicKey)
        var sharedTmp = shared
        if sharedTmp.count >= 32 {
            sharedTmp[31] ^= 0x80
        }
        return hash512(sharedTmp)
    }

    static func generateClientEkProof(key: [UInt8], beta: [UInt8], identity: TS3Identity) throws -> [UInt8] {
        var data = [UInt8](repeating: 0, count: 86)
        data.replaceSubrange(0..<32, with: key)
        data.replaceSubrange(32..<86, with: beta)
        return try identity.sign(data: data)
    }

    static func verifyClientEkProof(key: [UInt8], beta: [UInt8], signature: [UInt8], publicKey: [UInt8]) throws -> Bool {
        var data = [UInt8](repeating: 0, count: 86)
        data.replaceSubrange(0..<32, with: key)
        data.replaceSubrange(32..<86, with: beta)
        return try verifySignature(publicKey: publicKey, data: data, signature: signature)
    }

    static func verifySignature(publicKey: [UInt8], data: [UInt8], signature: [UInt8]) throws -> Bool {
        let x963 = try decodePublicKeyX963(publicKey)
        let verifyingKey = try P256.Signing.PublicKey(x963Representation: Data(x963))
        let sig = try P256.Signing.ECDSASignature(derRepresentation: Data(signature))
        return verifyingKey.isValidSignature(sig, for: Data(data))
    }

    static func decodePublicKey(_ der: [UInt8]) throws -> P256.KeyAgreement.PublicKey {
        let x963 = try decodePublicKeyX963(der)
        return try P256.KeyAgreement.PublicKey(x963Representation: Data(x963))
    }

    static func decodePublicKeyX963(_ der: [UInt8]) throws -> [UInt8] {
        let elements = try TS3DER.decodeSequence(der)
        guard elements.count >= 4 else {
            throw TS3Error.derDecodeFailed
        }
        let x = normalizeInteger(elements[2].content)
        let y = normalizeInteger(elements[3].content)
        return [0x04] + x + y
    }

    static func encodePublicKey(x: [UInt8], y: [UInt8]) -> [UInt8] {
        let bitString = TS3DER.encodeBitString(unusedBits: 7, bytes: [0x00])
        let length = TS3DER.encodeInteger([0x20])
        let xInt = TS3DER.encodeInteger(x)
        let yInt = TS3DER.encodeInteger(y)
        return TS3DER.encodeSequence([bitString, length, xInt, yInt])
    }

    static func sharedSecretHash(from secretBytes: [UInt8]) -> [UInt8] {
        if secretBytes.count == 32 {
            return hash128(secretBytes)
        }
        if secretBytes.count > 32 {
            return hash128(Array(secretBytes.suffix(32)))
        }
        var padded = [UInt8](repeating: 0, count: 32)
        let start = 32 - secretBytes.count
        padded.replaceSubrange(start..<32, with: secretBytes)
        return hash128(padded)
    }

    private static func normalizeInteger(_ bytes: [UInt8]) -> [UInt8] {
        var content = bytes
        if content.first == 0x00 {
            content.removeFirst()
        }
        if content.count < 32 {
            let pad = [UInt8](repeating: 0, count: 32 - content.count)
            content = pad + content
        } else if content.count > 32 {
            content = Array(content.suffix(32))
        }
        return content
    }
}
