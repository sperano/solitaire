import XCTest

/// The App Store screenshots, attached to the test result for `Scripts/screenshots.sh` to export.
/// Skipped unless the script runs it: it sets `SCREENSHOT_LOCALE` (as `TEST_RUNNER_SCREENSHOT_LOCALE`).
final class ScreenshotUITests: SolitaireUITestCase {
    private static let localeVariable = "SCREENSHOT_LOCALE"
    /// Lets a card flight or flip finish before the picture; a simulator just booted is slow.
    private static let animationSettle: TimeInterval = 2
    /// Lets the win cascade fall and the panel settle before the picture.
    private static let winSettle: TimeInterval = 3
    private static let drawsBeforeTheBoardShot = 3

    private var languageArguments: [String] = []

    override func setUp() async throws {
        continueAfterFailure = false
        guard let locale = ProcessInfo.processInfo.environment[Self.localeVariable] else {
            throw XCTSkip("screenshots are taken by Scripts/screenshots.sh")
        }
        // "fr-CA" is the language; the region format wants "fr_CA".
        let region = locale.replacingOccurrences(of: "-", with: "_")
        languageArguments = ["-AppleLanguages", "(\(locale))", "-AppleLocale", region]
    }

    private func launch(_ arguments: [String], seed: String? = SolitaireUITestCase.defaultSeed) {
        app = launchApp(extraArguments: ["-drawMode", "1"] + arguments + languageArguments, seed: seed)
    }

    private func snap(_ name: String, after settle: TimeInterval = animationSettle) {
        Thread.sleep(forTimeInterval: settle)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testBoardAndHint() {
        launch([])
        // Seed 42: the ace of hearts goes up, which turns a card over, then a few draws.
        tap("card-AH")
        tapStock(times: Self.drawsBeforeTheBoardShot)
        snap("01-board")
        tap("hintButton")
        snap("02-hint")
    }

    func testWinSettingsAndStatistics() {
        launch(["-position", "completable"])
        tap("autoCompleteButton")
        XCTAssertTrue(element("winOverlay").waitForExistence(timeout: Self.timeout))
        snap("03-win", after: Self.winSettle)
        tap("winNewGameButton")
        tap("settingsButton")
        XCTAssertTrue(element("settingsDoneButton").waitForExistence(timeout: Self.timeout))
        snap("04-settings")
        scrollTo("statisticsLink").tap()
        XCTAssertTrue(element("statsPlayed").waitForExistence(timeout: Self.timeout))
        snap("05-statistics")
    }
}
