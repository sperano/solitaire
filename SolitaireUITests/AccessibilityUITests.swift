import XCTest

/// Xcode's accessibility audit on every screen, the VoiceOver labels UI tests and players rely
/// on, and the toolbar at the largest accessibility text size.
final class AccessibilityUITests: SolitaireUITestCase {
    private static let largestTextArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
    private static let controls = ["hintButton", "undoButton", "newGameButton", "settingsButton"]
    private static let stats = ["movesLabel", "timeLabel", "scoreLabel"]
    /// Sheets and pushes animate in; auditing mid-animation reports contrast against the moving backdrop.
    private static let settleTime: TimeInterval = 1.5
    /// The audit's Dynamic Type and clipping checks predict trouble from the default size: they flag
    /// the card glyphs, which are sized to the card on purpose, and the toolbar's stats, which
    /// reflow instead (see `StatusBarView.layout`). The largest-text tests below check what
    /// really renders at that size instead.
    private static let auditedTypes = XCUIAccessibilityAuditType.all.subtracting([.dynamicType, .textClipped])

    private func settle() {
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "animations settle")], timeout: Self.settleTime)
    }

    /// A rank or suit drawn on a card face.
    private static let cardGlyphs: Set<String> = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "♣", "♦", "♥", "♠"]

    /// Runs the audit and fails once, listing every issue it found. `ignoringDimmedCards` skips the
    /// card glyphs a modal overlay dims on purpose; `ignoredContrast` names texts whose contrast the
    /// audit misreports.
    private func audit(
        ignoringDimmedCards: Bool = false, ignoredContrast: Set<String> = [],
        file: StaticString = #filePath, line: UInt = #line
    ) throws {
        settle()
        var issues: [String] = []
        try app.performAccessibilityAudit(for: Self.auditedTypes) { issue in
            let label = issue.element?.label ?? ""
            if issue.auditType == .contrast,
               ignoredContrast.contains(label) || (ignoringDimmedCards && Self.cardGlyphs.contains(label)) {
                return true
            }
            let element = issue.element.map { "\($0.identifier) '\($0.label)'" } ?? "?"
            issues.append("\(issue.auditType.rawValue) \(issue.compactDescription) on \(element)")
            return true
        }
        XCTAssertEqual(issues, [], file: file, line: line)
    }

    private func label(of identifier: String) -> String {
        let target = element(identifier)
        XCTAssertTrue(target.waitForExistence(timeout: Self.timeout), "\(identifier) not found")
        return target.label
    }

    // MARK: Audits

    func testBoardPassesTheAudit() throws {
        XCTAssertTrue(element("stock").waitForExistence(timeout: Self.timeout))
        try audit()
    }

    func testSettingsPassTheAudit() throws {
        tap("settingsButton")
        XCTAssertTrue(element("fourColorDeckToggle").waitForExistence(timeout: Self.timeout))
        // "Rules" renders in black on the grouped background (about 18:1), like the other headers,
        // which pass; the audit reports the first header of the sheet as failing anyway (Xcode 27.1).
        try audit(ignoredContrast: ["Rules"])
    }

    func testStatisticsPassTheAudit() throws {
        tap("settingsButton")
        tap("statisticsLink")
        XCTAssertTrue(element("statsPlayed").waitForExistence(timeout: Self.timeout))
        try audit()
    }

    func testWinScreenPassesTheAudit() throws {
        app.terminate()
        app = launchApp(extraArguments: ["-drawMode", "1", "-position", "completable"])
        tap("autoCompleteButton")
        XCTAssertTrue(element("winNewGameButton").waitForExistence(timeout: Self.timeout))
        try audit(ignoringDimmedCards: true)
    }

    func testBoardPassesTheAuditAtTheLargestTextSize() throws {
        app.terminate()
        app = launchApp(extraArguments: ["-drawMode", "1"] + Self.largestTextArguments)
        XCTAssertTrue(element("stock").waitForExistence(timeout: Self.timeout))
        try audit()
    }

    // MARK: Large text

    func testToolbarStaysUsableAtTheLargestTextSize() {
        app.terminate()
        app = launchApp(extraArguments: ["-drawMode", "1"] + Self.largestTextArguments)
        let screen = app.windows.firstMatch.frame
        for identifier in Self.controls + Self.stats {
            let target = element(identifier)
            XCTAssertTrue(target.waitForExistence(timeout: Self.timeout), identifier)
            XCTAssertTrue(screen.contains(target.frame), "\(identifier) is cut off at \(target.frame)")
        }
        for identifier in Self.controls {
            XCTAssertTrue(element(identifier).isHittable, identifier)
        }
        tap("settingsButton")
        XCTAssertTrue(element("settingsDoneButton").waitForExistence(timeout: Self.timeout))
        settle()
        XCTAssertTrue(element("settingsDoneButton").isHittable)
    }

    // MARK: Labels

    func testCardsAndPilesAreDescribed() {
        XCTAssertEqual(label(of: "card-AH"), "Ace of hearts, face up")
        XCTAssertEqual(label(of: "tableau-0"), "Column 1")
        XCTAssertEqual(label(of: "tableau-6"), "Column 7, 6 face down")
        XCTAssertEqual(label(of: "foundation-0"), "Foundation 1, empty")
        XCTAssertEqual(label(of: "waste"), "Waste, empty")
        XCTAssertEqual(label(of: "stock"), "Stock")

        tap("card-AH")
        expectCards(1, in: "foundation-0")
        XCTAssertEqual(label(of: "foundation-0"), "Foundation 1, ace of hearts on top")
    }

    func testControlsHaveNames() {
        let expected = [
            "hintButton": "Hint", "undoButton": "Undo", "newGameButton": "New Game", "settingsButton": "Settings",
        ]
        for (identifier, name) in expected {
            XCTAssertEqual(label(of: identifier), name, identifier)
        }
        XCTAssertEqual(label(of: "movesLabel"), "0 moves")
        XCTAssertEqual(label(of: "timeLabel"), "Time 0:00")
    }
}
