import XCTest
@testable import TS3Kit

final class TS3ErrorTests: XCTestCase {
    func testServerErrorDescriptionIncludesServerErrorId() {
        let error = TS3Error.serverErrorWithCode(id: 2568, message: "insufficient client permissions")

        XCTAssertEqual(error.localizedDescription, "insufficient client permissions (id 2568)")
    }

    func testLegacyServerErrorDescriptionUsesMessage() {
        let error = TS3Error.serverError(message: "invalid parameter")

        XCTAssertEqual(error.localizedDescription, "invalid parameter")
    }
}
