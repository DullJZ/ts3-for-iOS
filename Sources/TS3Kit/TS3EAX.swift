import Foundation
import CryptoSwift

enum TS3EAX {
    static func encrypt(key: [UInt8], nonce: [UInt8], header: [UInt8], plaintext: [UInt8], tagSize: Int) throws -> (ciphertext: [UInt8], tag: [UInt8]) {
        let nonceTag = try omac(key: key, prefix: 0x00, data: nonce)
        let headerTag = try omac(key: key, prefix: 0x01, data: header)

        let cipher = try AES(key: key, blockMode: CTR(iv: nonceTag), padding: .noPadding)
        let ciphertext = try cipher.encrypt(plaintext)

        let messageTag = try omac(key: key, prefix: 0x02, data: ciphertext)
        let tagFull = xor3(nonceTag, headerTag, messageTag)
        return (ciphertext, Array(tagFull.prefix(tagSize)))
    }

    static func decrypt(key: [UInt8], nonce: [UInt8], header: [UInt8], ciphertext: [UInt8], tag: [UInt8]) throws -> [UInt8] {
        let nonceTag = try omac(key: key, prefix: 0x00, data: nonce)
        let headerTag = try omac(key: key, prefix: 0x01, data: header)
        let messageTag = try omac(key: key, prefix: 0x02, data: ciphertext)
        let tagFull = xor3(nonceTag, headerTag, messageTag)
        guard tagFull.prefix(tag.count).elementsEqual(tag) else {
            throw TS3Error.invalidMac
        }

        let cipher = try AES(key: key, blockMode: CTR(iv: nonceTag), padding: .noPadding)
        return try cipher.decrypt(ciphertext)
    }

    private static func omac(key: [UInt8], prefix: UInt8, data: [UInt8]) throws -> [UInt8] {
        let message = [prefix] + data
        return try cmac(key: key, data: message)
    }

    private static func cmac(key: [UInt8], data: [UInt8]) throws -> [UInt8] {
        let blockSize = 16
        let zero = [UInt8](repeating: 0, count: blockSize)
        let aes = try AES(key: key, blockMode: ECB(), padding: .noPadding)
        let L = try aes.encrypt(zero)
        let K1 = subkey(from: L)
        let K2 = subkey(from: K1)

        let n = max(1, Int(ceil(Double(data.count) / Double(blockSize))))
        let lastBlockComplete = data.count > 0 && data.count % blockSize == 0

        var blocks: [[UInt8]] = []
        blocks.reserveCapacity(n)
        for i in 0..<n {
            let start = i * blockSize
            let end = min(start + blockSize, data.count)
            let block = Array(data[start..<end])
            blocks.append(block)
        }

        var last = blocks.removeLast()
        if lastBlockComplete {
            last = xor(last.padded(to: blockSize), K1)
        } else {
            last = xor(pad(block: last, blockSize: blockSize), K2)
        }
        blocks.append(last)

        var X = [UInt8](repeating: 0, count: blockSize)
        for block in blocks {
            X = try aes.encrypt(xor(X, block.padded(to: blockSize)))
        }
        return X
    }

    private static func subkey(from input: [UInt8]) -> [UInt8] {
        let blockSize = 16
        var output = [UInt8](repeating: 0, count: blockSize)
        var carry: UInt8 = 0
        for i in stride(from: blockSize - 1, through: 0, by: -1) {
            let byte = input[i]
            output[i] = (byte << 1) | carry
            carry = (byte & 0x80) > 0 ? 1 : 0
        }
        if carry > 0 {
            output[blockSize - 1] ^= 0x87
        }
        return output
    }

    private static func pad(block: [UInt8], blockSize: Int) -> [UInt8] {
        var padded = block
        padded.append(0x80)
        while padded.count < blockSize {
            padded.append(0x00)
        }
        return padded
    }

    private static func xor(_ a: [UInt8], _ b: [UInt8]) -> [UInt8] {
        let count = min(a.count, b.count)
        var out = [UInt8](repeating: 0, count: count)
        for i in 0..<count {
            out[i] = a[i] ^ b[i]
        }
        return out
    }

    private static func xor3(_ a: [UInt8], _ b: [UInt8], _ c: [UInt8]) -> [UInt8] {
        let count = min(a.count, b.count, c.count)
        var out = [UInt8](repeating: 0, count: count)
        for i in 0..<count {
            out[i] = a[i] ^ b[i] ^ c[i]
        }
        return out
    }
}

private extension Array where Element == UInt8 {
    func padded(to size: Int) -> [UInt8] {
        if count >= size { return self }
        return self + [UInt8](repeating: 0, count: size - count)
    }
}
