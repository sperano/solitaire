import XCTest

/// The app in French (Canada): the String Catalog is in the build and both kinds of string reach
/// the screen, SwiftUI's literal keys and the `String(localized:)` VoiceOver labels.
///
/// One language is enough. What this proves is the same for every language: the catalog is one
/// file, compiled once, and the code looks every string up the same way whatever the language.
/// What differs per language is the catalog's content, which `LocalizableCatalogTests` checks for
/// all of them (every key, plural form and argument), and that the bundle lists each language,
/// checked there too. A launch per language would cost a minute each and catch nothing more.
final class LocalizationUITests: SolitaireUITestCase {
    private static let frenchArguments = ["-AppleLanguages", "(fr-CA)", "-AppleLocale", "fr_CA"]

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
}
