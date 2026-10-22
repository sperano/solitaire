import XCTest

/// Starts from `-position` fixtures: `completable` finishes from the tableau alone, and
/// `oneMoveFromCompletable` needs the seven of hearts played from the waste first.
final class AutoCompleteUITests: SolitaireUITestCase {
    private static let fullSuit = 13

    private func launch(_ position: String) {
        app.terminate()
        app = launchApp(extraArguments: ["-drawMode", "1", "-position", position])
    }

    private func expectWon() {
        XCTAssertTrue(element("winOverlay").waitForExistence(timeout: Self.timeout))
        for index in 0 ..< Self.foundationCount {
            expectCards(Self.fullSuit, in: "foundation-\(index)")
        }
    }

    func testFinishButtonPlaysEveryCardToTheFoundations() {
        launch("completable")
        XCTAssertFalse(element("hintButton").exists, "Finish takes the hint button's place")
        tap("autoCompleteButton")
        expectWon()
    }

    func testFinishButtonAppearsOnceTheGameCanFinish() {
        launch("oneMoveFromCompletable")
        XCTAssertFalse(element("autoCompleteButton").waitForExistence(timeout: Self.absenceTimeout))
        tap("card-7H")
        XCTAssertTrue(element("autoCompleteButton").waitForExistence(timeout: Self.timeout))
        XCTAssertFalse(element("winOverlay").exists)
    }

    func testFinishAutomaticallyNeedsNoTap() {
        launch("oneMoveFromCompletable")
        tap("settingsButton")
        let toggle = app.switches["autoFinishToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: Self.timeout))
        toggle.switches.firstMatch.tap()
        XCTAssertEqual(toggle.value as? String, "1")
        tap("settingsDoneButton")

        tap("card-7H")
        expectWon()
    }
}
