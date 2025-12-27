import Foundation
import CryptoSwift

enum TS3EAX {
    static func encrypt(key: [UInt8], nonce: [UInt8], header: [UInt8], plaintext: [UInt8], tagSize: Int) throws -> (ciphertext: [UInt8], tag: [UInt8]) {
        let nonceTag = try omac(key: key, prefix: 0x00, data: nonce)
        let headerTag = try omac(key: key, prefix: 0x01, data: header)

        let ciphertext = try ctrCrypt(key: key, iv: nonceTag, data: plaintext)

        let messageTag = try omac(key: key, prefix: 0x02, data: ciphertext)
        let tagFull = xor3(nonceTag, headerTag, messageTag)
        return (ciphertext, Array(tagFull.prefix(tagSize)))
    }

    static func decrypt(key: [UInt8], nonce: [UInt8], header: [UInt8], ciphertext: [UInt8], tag: [UInt8]) throws -> [UInt8] {
        let nonceTag = try omac(key: key, prefix: 0x00, data: nonce)
        let headerTag = try omac(key: key, prefix: 0x01, data: header)
        let messageTag = try omac(key: key, prefix: 0x02, data: ciphertext)
        let tagFull = xor3(nonceTag, headerTag, messageTag)
        
        // Debug output
        print("[EAX DEBUG] nonceTag=\(nonceTag.map { String(format: "%02X", $0) }.joined())")
        print("[EAX DEBUG] headerTag=\(headerTag.map { String(format: "%02X", $0) }.joined())")
        print("[EAX DEBUG] messageTag=\(messageTag.map { String(format: "%02X", $0) }.joined())")
        print("[EAX DEBUG] computedTag=\(tagFull.prefix(8).map { String(format: "%02X", $0) }.joined())")
        print("[EAX DEBUG] expectedTag=\(tag.map { String(format: "%02X", $0) }.joined())")
        
        guard tagFull.prefix(tag.count).elementsEqual(tag) else {
            throw TS3Error.invalidMac
        }

        return try ctrCrypt(key: key, iv: nonceTag, data: ciphertext)
    }

    private static func omac(key: [UInt8], prefix: UInt8, data: [UInt8]) throws -> [UInt8] {
        // EAX spec: prefix is a full 16-byte block with 15 zeros followed by the prefix byte
        var prefixBlock = [UInt8](repeating: 0, count: 16)
        prefixBlock[15] = prefix
        let message = prefixBlock + data
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

    private static func ctrCrypt(key: [UInt8], iv: [UInt8], data: [UInt8]) throws -> [UInt8] {
        let aes = try AES(key: key, blockMode: ECB(), padding: .noPadding)
        var counter = iv
        var output: [UInt8] = []
        output.reserveCapacity(data.count)

        var offset = 0
        while offset < data.count {
            let blockLen = min(16, data.count - offset)
            let keystream = try aes.encrypt(counter)
            for i in 0..<blockLen {
                output.append(data[offset + i] ^ keystream[i])
            }
            offset += blockLen
            incrementCounter(&counter)
        }

        return output
    }

    private static func incrementCounter(_ counter: inout [UInt8]) {
        guard !counter.isEmpty else { return }
        for index in stride(from: counter.count - 1, through: 0, by: -1) {
            if counter[index] == 0xFF {
                counter[index] = 0x00
            } else {
                counter[index] &+= 1
                break
            }
        }
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
