import XCTest
@testable import TS3iOSApp

final class TS3ChannelDraftValidatorTests: XCTestCase {
    func testChannelDraftValidatorRejectsNonNumericOrder() {
        let messages = TS3ChannelDraftValidator.validationMessages(
            name: "Raid Room",
            neededTalkPower: "20",
            neededJoinPower: "25",
            neededSubscribePower: "10",
            neededDescriptionViewPower: "5",
            codecQuality: "10",
            codecLatencyFactor: "1",
            order: "after-lobby",
            deleteDelaySeconds: "3600",
            iconId: "456",
            maxClients: "12",
            maxClientsUnlimited: false,
            maxFamilyClients: "24",
            maxFamilyClientsUnlimited: false,
            maxFamilyClientsInherited: false
        )

        XCTAssertEqual(messages, ["Position must be numeric."])
    }

    func testChannelDraftValidatorRejectsNonNumericJoinPower() {
        let messages = TS3ChannelDraftValidator.validationMessages(
            name: "Raid Room",
            neededTalkPower: "",
            neededJoinPower: "join",
            neededSubscribePower: "",
            neededDescriptionViewPower: "",
            codecQuality: "",
            codecLatencyFactor: "",
            order: "",
            deleteDelaySeconds: "",
            iconId: "",
            maxClients: "",
            maxClientsUnlimited: true,
            maxFamilyClients: "",
            maxFamilyClientsUnlimited: true,
            maxFamilyClientsInherited: false
        )

        XCTAssertEqual(messages, ["Needed join power must be numeric."])
    }

    func testChannelDraftValidatorAcceptsOfficialEditableRanges() {
        let messages = TS3ChannelDraftValidator.validationMessages(
            name: "Raid Room",
            neededTalkPower: "",
            neededJoinPower: "",
            neededSubscribePower: "",
            neededDescriptionViewPower: "",
            codecQuality: "0",
            codecLatencyFactor: "10",
            order: "4",
            deleteDelaySeconds: "",
            iconId: "",
            maxClients: "",
            maxClientsUnlimited: true,
            maxFamilyClients: "",
            maxFamilyClientsUnlimited: true,
            maxFamilyClientsInherited: false
        )

        XCTAssertTrue(messages.isEmpty)
    }
}
