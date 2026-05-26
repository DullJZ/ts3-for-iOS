import Foundation
import XCTest
@testable import TS3Kit

final class TS3IconFileTests: XCTestCase {
    func testIconIdUsesStandardCRC32() {
        let data = Data("123456789".utf8)

        XCTAssertEqual(TS3IconFile.iconId(for: data), 0xCBF43926)
    }

    func testIconPathUsesVirtualServerIconName() {
        XCTAssertEqual(TS3IconFile.path(for: 0xCBF43926), "/icon_3421780262")
    }
}
