import XCTest

/// Deal numbers: shown and shared from Settings, typed to play a specific deal, replayed from the
/// new-game dialog, and the "Dealing…" state of winnable deals.
final class DealUITests: SolitaireUITestCase {
    /// Seed 7's tableau top differs from seed 42's (2♣ in the first column).
    private static let otherSeed = "7"
    /// Finding a winnable deal in a debug build can take a while on a loaded runner.
    private static let dealingTimeout: TimeInterval = 90

    /// Opens Settings and scrolls until the whole Deal section is on screen.
    private func openDealSection() {
        tap("settingsButton")
        XCTAssertTrue(element("drawModePicker").waitForExistence(timeout: Self.timeout))
        scrollTo("playDealButton")
    }

    /// The alert's text field; SwiftUI alerts do not pass identifiers on to their fields.
    private var dealNumberField: XCUIElement { app.alerts.firstMatch.textFields.firstMatch }

    private var dealNumber: String {
        (element("dealNumberLabel").value as? String ?? "").filter(\.isWholeNumber)
    }

    func testSettingsShowTheDealNumberAndAShareButton() {
        openDealSection()
        XCTAssertEqual(dealNumber, Self.defaultSeed)
        XCTAssertTrue(element("shareDealButton").exists)
    }

    func testPlayingADealNumberDealsThatGame() {
        tapStock()
        openDealSection()
        tap("playDealButton")
        XCTAssertTrue(dealNumberField.waitForExistence(timeout: Self.timeout))
        dealNumberField.tap()
        dealNumberField.typeText(Self.otherSeed)
        tap("confirmPlayDealButton")

        XCTAssertEqual(moves, "0")
        expectCards(Self.stockSize, in: "stock")
        XCTAssertFalse(element("card-2C").exists, "seed 42's first column top is gone")
        openDealSection()
        XCTAssertEqual(dealNumber, Self.otherSeed)
    }

    func testPlayingWithNothingTypedChangesNothing() {
        tapStock()
        openDealSection()
        tap("playDealButton")
        XCTAssertTrue(dealNumberField.waitForExistence(timeout: Self.timeout))
        tap("confirmPlayDealButton")

        XCTAssertTrue(dealNumberField.waitForNonExistence(timeout: Self.timeout), "the alert closed")
        XCTAssertTrue(element("dealNumberLabel").exists, "Settings stay open")
        XCTAssertEqual(dealNumber, Self.defaultSeed)
        tap("settingsDoneButton")
        XCTAssertEqual(moves, "1")
    }

    func testReplayingTheDealFromTheNewGameDialogStartsItOver() {
        tapStock()
        XCTAssertEqual(moves, "1")
        tap("newGameButton")
        tap("replayDealButton")

        XCTAssertEqual(moves, "0")
        expectCards(Self.stockSize, in: "stock")
        XCTAssertTrue(element("card-2C").exists, "still seed 42")
        openDealSection()
        XCTAssertEqual(dealNumber, Self.defaultSeed)
    }

    func testWinnableDealsOnlyDealsAPlayableGameAfterSearching() {
        app.terminate()
        app = launchApp(extraArguments: ["-drawMode", "1", "-winnableDealsOnly", "1"], seed: nil)

        let hint = element("hintButton")
        XCTAssertTrue(hint.waitForExistence(timeout: Self.timeout))
        XCTAssertTrue(hint.wait(for: \.isEnabled, toEqual: true, timeout: Self.dealingTimeout), "dealing finished")
        XCTAssertFalse(element("dealingLabel").exists)
        expectCards(Self.stockSize, in: "stock")

        tap("newGameButton")
        XCTAssertTrue(hint.wait(for: \.isEnabled, toEqual: true, timeout: Self.dealingTimeout))
        expectCards(Self.stockSize, in: "stock")
        XCTAssertEqual(moves, "0")
    }
}
