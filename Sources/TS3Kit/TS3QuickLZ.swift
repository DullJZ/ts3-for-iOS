import Foundation

enum TS3QuickLZ {
    private static let hashValues = 4096
    private static let minOffset = 2
    private static let unconditionalMatchLen = 6
    private static let uncompressedEnd = 4
    private static let cwordLen = 4

    static func headerLength(_ source: [UInt8]) -> Int {
        return (source[0] & 2) == 2 ? 9 : 3
    }

    static func sizeDecompressed(_ source: [UInt8]) -> Int {
        if headerLength(source) == 9 {
            return Int(fastRead(source, 5, 4))
        }
        return Int(fastRead(source, 2, 1))
    }

    static func decompress(_ source: [UInt8], maximum: Int) throws -> [UInt8] {
        let level = (source[0] >> 2) & 0x3
        if level != 1 && level != 3 {
            throw TS3Error.compressionUnsupported
        }

        let size = sizeDecompressed(source)
        if size > maximum {
            throw TS3Error.decompressionTooLarge
        }

        var src = headerLength(source)
        var dst = 0
        var cwordVal: UInt32 = 1
        var destination = [UInt8](repeating: 0, count: size)
        var hashtable = [Int](repeating: 0, count: hashValues)
        var hashCounter = [UInt8](repeating: 0, count: hashValues)
        let lastMatchStart = size - unconditionalMatchLen - uncompressedEnd - 1
        var lastHashed = -1
        var fetch = 0

        if (source[0] & 1) != 1 {
            let header = headerLength(source)
            return Array(source[header..<header + size])
        }

        while true {
            if cwordVal == 1 {
                cwordVal = UInt32(fastRead(source, src, 4))
                src += 4
                if dst <= lastMatchStart {
                    if level == 1 {
                        fetch = Int(fastRead(source, src, 3))
                    } else {
                        fetch = Int(fastRead(source, src, 4))
                    }
                }
            }

            if (cwordVal & 1) == 1 {
                var matchLen = 0
                var offset2 = 0
                cwordVal >>= 1

                if level == 1 {
                    let hash = (fetch >> 4) & 0xfff
                    offset2 = hashtable[hash]

                    if (fetch & 0xf) != 0 {
                        matchLen = (fetch & 0xf) + 2
                        src += 2
                    } else {
                        matchLen = Int(source[src + 2]) & 0xff
                        src += 3
                    }
                } else {
                    var offset = 0
                    if (fetch & 3) == 0 {
                        offset = (fetch & 0xff) >> 2
                        matchLen = 3
                        src += 1
                    } else if (fetch & 2) == 0 {
                        offset = (fetch & 0xffff) >> 2
                        matchLen = 3
                        src += 2
                    } else if (fetch & 1) == 0 {
                        offset = (fetch & 0xffff) >> 6
                        matchLen = ((fetch >> 2) & 15) + 3
                        src += 2
                    } else if (fetch & 127) != 3 {
                        offset = (fetch >> 7) & 0x1ffff
                        matchLen = ((fetch >> 2) & 0x1f) + 2
                        src += 3
                    } else {
                        offset = fetch >> 15
                        matchLen = ((fetch >> 7) & 255) + 3
                        src += 4
                    }
                    offset2 = dst - offset
                }

                destination[dst] = destination[offset2]
                destination[dst + 1] = destination[offset2 + 1]
                destination[dst + 2] = destination[offset2 + 2]

                if matchLen > 3 {
                    for i in 3..<matchLen {
                        destination[dst + i] = destination[offset2 + i]
                    }
                }
                dst += matchLen

                if level == 1 {
                    fetch = Int(fastRead(destination, lastHashed + 1, 3))
                    while lastHashed < dst - matchLen {
                        lastHashed += 1
                        let hash = ((fetch >> 12) ^ fetch) & (hashValues - 1)
                        hashtable[hash] = lastHashed
                        hashCounter[hash] = 1
                        fetch = (fetch >> 8 & 0xffff) | (Int(destination[lastHashed + 3]) << 16)
                    }
                    fetch = Int(fastRead(source, src, 3))
                } else {
                    fetch = Int(fastRead(source, src, 4))
                }
                lastHashed = dst - 1
            } else {
                if dst <= lastMatchStart {
                    destination[dst] = source[src]
                    dst += 1
                    src += 1
                    cwordVal >>= 1

                    if level == 1 {
                        while lastHashed < dst - 3 {
                            lastHashed += 1
                            let fetch2 = Int(fastRead(destination, lastHashed, 3))
                            let hash = ((fetch2 >> 12) ^ fetch2) & (hashValues - 1)
                            hashtable[hash] = lastHashed
                            hashCounter[hash] = 1
                        }
                        fetch = (fetch >> 8 & 0xffff) | (Int(source[src + 2]) << 16)
                    } else {
                        fetch = (fetch >> 8 & 0xffff) | (Int(source[src + 2]) << 16) | (Int(source[src + 3]) << 24)
                    }
                } else {
                    while dst <= size - 1 {
                        if cwordVal == 1 {
                            src += cwordLen
                            cwordVal = 0x80000000
                        }
                        destination[dst] = source[src]
                        dst += 1
                        src += 1
                        cwordVal >>= 1
                    }
                    return destination
                }
            }
        }
    }

    private static func fastRead(_ a: [UInt8], _ i: Int, _ numBytes: Int) -> Int {
        var l = 0
        for j in 0..<numBytes {
            l |= Int(a[i + j]) << (j * 8)
        }
        return l
    }
}
