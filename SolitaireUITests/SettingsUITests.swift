import XCTest

final class SettingsUITests: SolitaireUITestCase {
    private func openSettings() -> XCUIElement {
        tap("settingsButton")
        let picker = element("drawModePicker")
        XCTAssertTrue(picker.waitForExistence(timeout: Self.timeout))
        return picker
    }

    func testChoosingDrawThreeAppliesToTheNextGame() {
        tapStock()
        expectCards(1, in: "waste")

        let picker = openSettings()
        picker.buttons["Draw 3"].tap()
        tap("settingsDoneButton")

        // The game in progress keeps drawing one card at a time.
        tapStock()
        expectCards(2, in: "waste")

        tap("newGameButton")
        tap("confirmNewGameButton")
        tapStock()
        expectCards(Self.cardsPerDrawThree, in: "waste")
        expectCards(Self.stockSize - Self.cardsPerDrawThree, in: "stock")
    }

    func testSettingsShowsTheSelectedDrawModeWhenReopened() {
        var picker = openSettings()
        XCTAssertTrue(picker.buttons["Draw 1"].isSelected)
        picker.buttons["Draw 3"].tap()
        tap("settingsDoneButton")

        picker = openSettings()
        XCTAssertTrue(picker.buttons["Draw 3"].isSelected)
        XCTAssertFalse(picker.buttons["Draw 1"].isSelected)
    }

    func testHapticsAreOnUntilTurnedOff() {
        _ = openSettings()
        let toggle = app.switches["hapticsToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: Self.timeout))
        XCTAssertEqual(toggle.value as? String, "1")
        toggle.switches.firstMatch.tap()
        tap("settingsDoneButton")

        _ = openSettings()
        XCTAssertEqual(app.switches["hapticsToggle"].value as? String, "0")
    }

    func testWinnableDealsOnlyIsOffUntilTurnedOn() {
        _ = openSettings()
        let toggle = app.switches["winnableDealsOnlyToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: Self.timeout))
        XCTAssertEqual(toggle.value as? String, "0")
        toggle.switches.firstMatch.tap()
        tap("settingsDoneButton")

        _ = openSettings()
        XCTAssertEqual(app.switches["winnableDealsOnlyToggle"].value as? String, "1")
    }

    func testTurningTheTimerOffHidesTheClockAndTheWinTime() {
        app.terminate()
        app = launchApp(extraArguments: ["-drawMode", "1", "-position", "completable"])
        XCTAssertTrue(element("timeLabel").waitForExistence(timeout: Self.timeout))
        _ = openSettings()
        let toggle = app.switches["timerToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: Self.timeout))
        XCTAssertEqual(toggle.value as? String, "1")
        toggle.switches.firstMatch.tap()
        tap("settingsDoneButton")

        XCTAssertFalse(element("timeLabel").waitForExistence(timeout: Self.absenceTimeout))
        tap("autoCompleteButton")
        let summary = element("winSummary")
        XCTAssertTrue(summary.waitForExistence(timeout: Self.timeout))
        XCTAssertFalse(summary.label.contains(" in "), summary.label)
    }

    func testCardChoicesAreKeptWhenSettingsReopens() {
        _ = openSettings()
        let largePrint = app.switches["largePrintToggle"]
        XCTAssertTrue(largePrint.waitForExistence(timeout: Self.timeout))
        XCTAssertEqual(largePrint.value as? String, "0")
        largePrint.switches.firstMatch.tap()
        choose("Red lattice", in: "cardBackPicker")
        choose("Charcoal", in: "feltPicker")
        tap("settingsDoneButton")

        _ = openSettings()
        XCTAssertEqual(app.switches["largePrintToggle"].value as? String, "1")
        expectChoice("Red lattice", in: "cardBackPicker")
        expectChoice("Charcoal", in: "feltPicker")
    }

    private func choose(_ option: String, in picker: String) {
        scrollTo(picker)
        tap(picker)
        let item = app.buttons[option]
        XCTAssertTrue(item.waitForExistence(timeout: Self.timeout), "\(option) not offered by \(picker)")
        item.tap()
        expectChoice(option, in: picker)
    }

    /// A menu picker has no value: it shows its choice as a text inside the button ("Card back, Blue").
    private func expectChoice(_ option: String, in picker: String, file: StaticString = #filePath, line: UInt = #line) {
        let target = scrollTo(picker, file: file, line: line)
        XCTAssertTrue(target.staticTexts[option].exists, "\(picker): \(target.label)", file: file, line: line)
    }
}
