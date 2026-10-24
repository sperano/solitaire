import XCTest
@testable import Solitaire

/// `Localizable.xcstrings`, read from the repository: every string the app shows has a French
/// (Canada) translation, and every translation takes the same arguments as the English. A
/// missing argument would print garbage; a wrong type would crash the formatting.
final class LocalizableCatalogTests: XCTestCase {
    private static let catalogURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Solitaire/Resources/Localizable.xcstrings")
    private static let sourceLanguage = "en"
    private static let french = "fr-CA"
    /// The plural categories each language needs (Unicode CLDR): French "one" covers 0 and 1,
    /// "many" exact millions.
    private static let pluralCategories = [sourceLanguage: ["one", "other"], french: ["one", "many", "other"]]
    private static let translated = "translated"
    private static let stale = "stale"
    /// `%@`, `%lld`, `%1$@`, `%2$lld`, `%%`, `%#@name@`: what a format string can take.
    private static var specifier: Regex<(Substring, Substring?, Substring)> {
        /%(?:(\d+)\$)?(#@\w+@|ll[du]|l?[du]|@|%)/
    }

    private struct Catalog: Decodable {
        let sourceLanguage: String
        let strings: [String: Entry]
    }

    private struct Entry: Decodable {
        let extractionState: String?
        let localizations: [String: Localization]?
    }

    private struct Localization: Decodable {
        let stringUnit: StringUnit?
        let variations: Variations?
    }

    private struct Variations: Decodable {
        let plural: [String: Form]?
    }

    private struct Form: Decodable {
        let stringUnit: StringUnit
    }

    private struct StringUnit: Decodable {
        let state: String
        let value: String
    }

    private func catalog() throws -> Catalog {
        try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: Self.catalogURL))
    }

    func testTheSourceLanguageIsEnglish() throws {
        XCTAssertEqual(try catalog().sourceLanguage, Self.sourceLanguage)
    }

    func testTheAppShipsEnglishAndFrench() {
        // Without the catalog in the build, every key would pass here and the app stay in English.
        XCTAssertEqual(Bundle(for: GameViewModel.self).localizations.sorted(), [Self.sourceLanguage, Self.french])
    }

    func testEveryKeyHasAFrenchTranslation() throws {
        for (key, entry) in try catalog().strings {
            let french = try XCTUnwrap(entry.localizations?[Self.french], "no French for \"\(key)\"")
            for (category, unit) in try units(of: french, language: Self.french, key: key) {
                XCTAssertEqual(unit.state, Self.translated, "\"\(key)\" \(category) is not translated")
                XCTAssertFalse(unit.value.trimmingCharacters(in: .whitespaces).isEmpty, "\"\(key)\" \(category)")
            }
        }
    }

    func testEnglishPluralsHaveEveryForm() throws {
        for (key, entry) in try catalog().strings {
            guard let english = entry.localizations?[Self.sourceLanguage], english.variations != nil else { continue }
            _ = try units(of: english, language: Self.sourceLanguage, key: key)
        }
    }

    func testTranslationsTakeTheSameArgumentsAsTheEnglish() throws {
        for (key, entry) in try catalog().strings {
            let expected = Self.arguments(in: sourceFormat(key: key, entry: entry))
            for (language, localization) in entry.localizations ?? [:] {
                for (category, unit) in try units(of: localization, language: language, key: key) {
                    XCTAssertEqual(
                        Self.arguments(in: unit.value), expected,
                        "\"\(key)\" in \(language) \(category): \"\(unit.value)\""
                    )
                }
            }
        }
    }

    func testNoKeyIsStale() throws {
        // Stale keys are strings the code no longer uses; `make strings` marks them, delete them.
        let stale = try catalog().strings.filter { $0.value.extractionState == Self.stale }.keys
        XCTAssertEqual(stale.sorted(), [])
    }

    func testArgumentsAreReadByPosition() {
        XCTAssertEqual(Self.arguments(in: "%1$@ in %2$@"), Self.arguments(in: "%@ in %@"))
        XCTAssertEqual(Self.arguments(in: "%2$@ de %1$@"), ["2:@", "1:@"].sorted())
        XCTAssertNotEqual(Self.arguments(in: "%lld cartes"), Self.arguments(in: "%@ cartes"))
        XCTAssertEqual(Self.arguments(in: "100 %%"), [])
    }

    // MARK: Helpers

    /// The string units of a localisation: one, or one per plural form, which must all be there.
    private func units(of localization: Localization, language: String, key: String) throws -> [(String, StringUnit)] {
        if let unit = localization.stringUnit { return [("", unit)] }
        let forms = try XCTUnwrap(localization.variations?.plural, "\"\(key)\" in \(language): no string")
        let needed = try XCTUnwrap(Self.pluralCategories[language], "unexpected language \(language)")
        XCTAssertEqual(Set(forms.keys), Set(needed), "\"\(key)\" in \(language): plural forms")
        return forms.sorted { $0.key < $1.key }.map { ($0.key, $0.value.stringUnit) }
    }

    /// The English format: the key itself unless the catalog gives English its own value.
    private func sourceFormat(key: String, entry: Entry) -> String {
        let english = entry.localizations?[Self.sourceLanguage]
        return english?.stringUnit?.value ?? english?.variations?.plural?["other"]?.stringUnit.value ?? key
    }

    /// Each argument as "position:type", sorted, so `%@ in %@` and `%2$@ en %1$@` compare equal.
    private static func arguments(in format: String) -> [String] {
        var next = 1
        var result: [String] = []
        for match in format.matches(of: specifier) where match.output.2 != "%" {
            let position = match.output.1.flatMap { Int($0) } ?? next
            next = position + 1
            result.append("\(position):\(match.output.2.replacing("u", with: "d"))")
        }
        return result.sorted()
    }
}
