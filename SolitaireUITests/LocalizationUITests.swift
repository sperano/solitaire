import XCTest

/// The app in French (Canada): the String Catalog is in the build and both kinds of string reach
/// the screen, SwiftUI's literal keys and the `String(localized:)` VoiceOver labels.
///
/// French proves the localisation plumbing. Portuguese and Chinese also get targeted large-text
/// checks because their translations were added with that requirement.
final class LocalizationUITests: SolitaireUITestCase {
    private static let frenchArguments = ["-AppleLanguages", "(fr-CA)", "-AppleLocale", "fr_CA"]
    private static let chineseLargestTextArguments = [
        "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN",
        "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    private static let portugueseLargestTextArguments = [
        "-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR",
        "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
    ]

    override func setUp() async throws {
        continueAfterFailure = false
        app = launchApp(extraArguments: ["-drawMode", "1"] + Self.frenchArguments)
    }

    func testTheBoardSpeaksFrench() {
        XCTAssertEqual(label(of: "stock"), "Pioche")
        XCTAssertEqual(value(of: "stock"), "\(Self.stockSize) cartes")
        // Seed 42: the third column is the queen of clubs on two face-down cards.
        XCTAssertEqual(label(of: "card-QC"), "Dame de trèfle, face visible")
        XCTAssertEqual(label(of: "tableau-2"), "Colonne 3, 2 cartes cachées")
        XCTAssertEqual(label(of: "tableau-1"), "Colonne 2, 1 carte cachée")
        XCTAssertEqual(label(of: "movesLabel"), "0 coup")
    }

    func testTheControlsAndSettingsAreInFrench() {
        XCTAssertEqual(label(of: "newGameButton"), "Nouvelle partie")
        tap("settingsButton")
        XCTAssertTrue(app.navigationBars["Réglages"].waitForExistence(timeout: Self.timeout))
        XCTAssertTrue(element("drawModePicker").buttons["Piger 3"].exists)
        XCTAssertEqual(label(of: "winnableDealsOnlyToggle"), "Donnes gagnables seulement")
    }

    func testPortugueseFitsAtTheLargestTextSize() throws {
        app.terminate()
        app = launchApp(extraArguments: ["-drawMode", "1"] + Self.portugueseLargestTextArguments)

        XCTAssertEqual(label(of: "stock"), "Monte")
        XCTAssertEqual(label(of: "card-QC"), "Dama de paus, virada para cima")
        XCTAssertEqual(label(of: "movesLabel"), "0 jogada")
        XCTAssertTrue(app.windows.firstMatch.frame.contains(element("movesLabel").frame))

        tap("settingsButton")
        XCTAssertTrue(app.navigationBars["Ajustes"].waitForExistence(timeout: Self.timeout))
        XCTAssertEqual(label(of: "winnableDealsOnlyToggle"), "Apenas distribuições solucionáveis")
        try auditForClippedText()

        scrollTo("largePrintToggle")
        XCTAssertEqual(label(of: "largePrintToggle"), "Caracteres grandes")
        try auditForClippedText()
    }

    func testChineseFitsAtTheLargestTextSize() throws {
        app.terminate()
        app = launchApp(extraArguments: ["-drawMode", "1"] + Self.chineseLargestTextArguments)

        XCTAssertEqual(label(of: "stock"), "牌库")
        XCTAssertEqual(label(of: "card-QC"), "梅花Q，正面朝上")
        XCTAssertEqual(label(of: "movesLabel"), "0步")
        XCTAssertTrue(app.windows.firstMatch.frame.contains(element("movesLabel").frame))

        tap("settingsButton")
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: Self.timeout))
        XCTAssertEqual(label(of: "winnableDealsOnlyToggle"), "仅限可解牌局")
        try auditForClippedText()

        scrollTo("largePrintToggle")
        XCTAssertEqual(label(of: "largePrintToggle"), "大号牌面")
        try auditForClippedText()
    }

    private func auditForClippedText() throws {
        try runAccessibilityAudit {
            try app.performAccessibilityAudit(for: .textClipped)
        }
    }
}
