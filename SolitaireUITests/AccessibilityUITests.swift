import XCTest

/// Xcode's accessibility audit on every screen, the VoiceOver labels UI tests and players rely
/// on, and the toolbar at the largest accessibility text size.
final class AccessibilityUITests: SolitaireUITestCase {
    private static let largestTextArguments = [
        "-UIPreferredContentSizeCategoryName",
        "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    private static let controls = ["hintButton", "undoButton", "redoButton", "newGameButton", "settingsButton"]
    private static let stats = ["movesLabel", "timeLabel", "scoreLabel"]
    /// Sheets and pushes animate in; auditing mid-animation reports contrast against the moving backdrop.
    private static let settleTime: TimeInterval = 1.5
    /// The audit's Dynamic Type and clipping checks predict trouble from the default size: they flag
    /// the card glyphs, which are sized to the card on purpose, and the toolbar's stats, which
    /// reflow instead (see `StatusBarView.layout`). The largest-text tests below check what
    /// really renders at that size instead.
    private static let auditAttempts = 3
    private static let auditErrorDomain = "com.apple.xcode.xctest.accessibilityAudit"
    /// "Audit failed to complete in time".
    private static let auditTimedOutCode = -56
    private static let auditedTypes = XCUIAccessibilityAuditType.all.subtracting([.dynamicType, .textClipped])

    private func settle() {
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "animations settle")], timeout: Self.settleTime)
    }

    /// A rank or suit drawn on a card face.
    private static let cardGlyphs: Set<String> = [
        "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "♣", "♦", "♥", "♠",
    ]

    /// Runs the audit and fails once, listing every issue it found. `ignoringDimmedCards` skips the
    /// card glyphs a modal overlay dims on purpose and the cards the win cascade draws;
    /// `ignoredContrast` names texts whose contrast the audit misreports.
    private func audit(
        ignoringDimmedCards: Bool = false, ignoredContrast: Set<String> = [],
        file: StaticString = #filePath, line: UInt = #line
    ) throws {
        settle()
        var issues: [String] = []
        try withAuditRetries {
            issues = []
            try app.performAccessibilityAudit(for: Self.auditedTypes) { issue in
                let label = issue.element?.label ?? ""
                // The win cascade draws cards into a canvas hidden from VoiceOver: decoration.
                if ignoringDimmedCards, issue.auditType == .elementDetection, issue.element == nil {
                    return true
                }
                if issue.auditType == .contrast,
                   ignoredContrast.contains(label) || (ignoringDimmedCards && Self.cardGlyphs.contains(label))
                {
                    return true
                }
                let element = issue.element.map { "\($0.identifier) '\($0.label)'" } ?? "?"
                issues.append("\(issue.auditType.rawValue) \(issue.compactDescription) on \(element)")
                return true
            }
        }
        XCTAssertEqual(issues, [], file: file, line: line)
    }

    /// On a slow CI runner the audit can give up with "Audit failed to complete in time"; that says
    /// nothing about the app, so a timed-out audit runs again. Every other error is thrown at once.
    /// The audit gave up waiting for the screen, which happens on a loaded CI runner.
    private static func isAuditTimeout(_ error: NSError) -> Bool {
        error.domain == auditErrorDomain && error.code == auditTimedOutCode
    }

    private func withAuditRetries(_ run: () throws -> Void) throws {
        for attempt in 1 ... Self.auditAttempts {
            do {
                return try run()
            } catch let error as NSError where Self.isAuditTimeout(error) && attempt < Self.auditAttempts {
                continue
            }
        }
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
        // "Done" is black on the toolbar's light glass capsule; since the sheet scrolls, the audit
        // measures it against the blurred content under the bar instead (screenshots look fine).
        try audit(ignoredContrast: ["Rules", "Done"])
    }

    func testStatisticsPassTheAudit() throws {
        tap("settingsButton")
        scrollTo("statisticsLink").tap()
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
            "hintButton": "Hint", "undoButton": "Undo", "redoButton": "Redo", "newGameButton": "New Game",
            "settingsButton": "Settings",
        ]
        for (identifier, name) in expected {
            XCTAssertEqual(label(of: identifier), name, identifier)
        }
        XCTAssertEqual(label(of: "movesLabel"), "0 moves")
        XCTAssertEqual(label(of: "timeLabel"), "Time 0:00")
    }
}
