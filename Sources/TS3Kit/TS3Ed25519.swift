import Foundation
import Clibsodium

enum TS3Ed25519 {
    static let sodiumInitialized: Bool = {
        return sodium_init() >= 0
    }()

    static func clamp(_ bytes: inout [UInt8]) {
        guard bytes.count >= 32 else { return }
        bytes[0] &= 248
        bytes[31] &= 127
        bytes[31] |= 64
    }

    static func scalarMult(privateKey: [UInt8], publicKey: [UInt8]) throws -> [UInt8] {
        _ = sodiumInitialized
        var output = [UInt8](repeating: 0, count: 32)
        var sk = privateKey
        var pk = publicKey
        let result = crypto_scalarmult_ed25519_noclamp(&output, &sk, &pk)
        if result != 0 {
            throw TS3Error.cryptoFailed
        }
        return output
    }

    static func scalarMultBase(privateKey: [UInt8]) throws -> [UInt8] {
        _ = sodiumInitialized
        var output = [UInt8](repeating: 0, count: 32)
        var sk = privateKey
        let result = crypto_scalarmult_ed25519_base_noclamp(&output, &sk)
        if result != 0 {
            throw TS3Error.cryptoFailed
        }
        return output
    }

    static func add(_ lhs: [UInt8], _ rhs: [UInt8]) throws -> [UInt8] {
        _ = sodiumInitialized
        var output = [UInt8](repeating: 0, count: 32)
        var left = lhs
        var right = rhs
        let result = crypto_core_ed25519_add(&output, &left, &right)
        if result != 0 {
            throw TS3Error.cryptoFailed
        }
        return output
    }
}
