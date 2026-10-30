import XCTest
@testable import Solitaire

/// The App Store text under `AppStore/metadata/<locale>/`, one file per App Store Connect field
/// (the layout fastlane deliver reads): every locale has every field, within the store's limits.
/// The fields that are not translated (copyright, category) sit in `AppStore/metadata/` itself.
/// The locales are the folders there, so adding a language adds a folder and nothing here.
final class AppStoreMetadataTests: XCTestCase {
    private static let repository = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent()
    private static let metadata = repository.appendingPathComponent("AppStore/metadata")
    /// The listing every other locale falls back to; App Store Connect calls it the primary language.
    private static let primaryLocale = "en-US"
    /// The locale codes App Store Connect accepts (fastlane deliver's names), so a folder named
    /// `fr_CA` or `fr` fails here instead of at upload.
    private static let storeLocales: Set = [
        "ar-SA", "ca", "cs", "da", "de-DE", "el", "en-AU", "en-CA", "en-GB", "en-US", "es-ES", "es-MX",
        "fi", "fr-CA", "fr-FR", "he", "hi", "hr", "hu", "id", "it", "ja", "ko", "ms", "nl-NL", "no", "pl",
        "pt-BR", "pt-PT", "ro", "ru", "sk", "sv", "th", "tr", "uk", "vi", "zh-Hans", "zh-Hant",
    ]
    private static let regionSeparator: Character = "-"
    private static var locales: [String] {
        get throws {
            try FileManager.default.contentsOfDirectory(atPath: metadata.path)
                .filter { !$0.hasPrefix(".") && !$0.hasSuffix(textExtension) }
                .sorted()
        }
    }

    /// App Store Connect's limits, in characters.
    private static let limits = [
        "name": 30,
        "subtitle": 30,
        "promotional_text": 170,
        "keywords": 100,
        "description": 4_000,
    ]
    /// The first version takes no release notes; every later one has them in every locale.
    private static let releaseNotes = "release_notes"
    private static let releaseNotesLimit = 4_000
    private static let urlFields = ["privacy_url", "support_url"]
    private static let sharedFields = ["copyright", "primary_category", "primary_first_sub_category"]
    /// Where `privacy_url` points: a file in this repository, as GitHub shows it on main.
    private static let repositoryFilePrefix = "https://github.com/sperano/solitaire/blob/main/"
    private static let keywordSeparator: Character = ","
    private static let textExtension = ".txt"

    private func field(_ name: String, in locale: String? = nil) throws -> String {
        let directory = locale.map { Self.metadata.appendingPathComponent($0) } ?? Self.metadata
        let url = directory.appendingPathComponent(name + Self.textExtension)
        return try String(contentsOf: url, encoding: .utf8).trimmingCharacters(in: .newlines)
    }

    private func fieldNames(in directory: URL) throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasSuffix(Self.textExtension) }
            .map { String($0.dropLast(Self.textExtension.count)) }
            .sorted()
    }

    private static func languageCode(of locale: String) -> String {
        String(locale.prefix { $0 != regionSeparator })
    }

    func testTheLocalesAreAppStoreLocalesWithThePrimaryOne() throws {
        let locales = try Self.locales
        XCTAssertTrue(locales.contains(Self.primaryLocale))
        XCTAssertEqual(Set(locales).subtracting(Self.storeLocales), [])
    }

    func testTheStoreAndTheAppHaveTheSameLanguages() throws {
        // A listing in a language the app lacks would promise what it doesn't show, and a language
        // with no listing would go unseen in the store.
        let app = Set(Bundle(for: GameViewModel.self).localizations.map(Self.languageCode))
        let store = try Set(Self.locales.map(Self.languageCode))
        XCTAssertEqual(store, app)
    }

    func testEveryLocaleHasEveryFieldWithinItsLimit() throws {
        for locale in try Self.locales {
            for (name, limit) in Self.limits {
                let text = try field(name, in: locale)
                XCTAssertFalse(text.isEmpty, "\(locale) \(name)")
                XCTAssertLessThanOrEqual(text.count, limit, "\(locale) \(name)")
            }
        }
    }

    func testThereAreNoOtherFields() throws {
        XCTAssertEqual(try fieldNames(in: Self.metadata), Self.sharedFields.sorted())
        let expected = Self.limits.keys + Self.urlFields
        for locale in try Self.locales {
            let names = try fieldNames(in: Self.metadata.appendingPathComponent(locale))
            XCTAssertEqual(names.filter { $0 != Self.releaseNotes }, expected.sorted(), locale)
        }
    }

    func testReleaseNotesAreInEveryLocaleOrNone() throws {
        let locales = try Self.locales
        let present = try locales.filter { locale in
            try fieldNames(in: Self.metadata.appendingPathComponent(locale)).contains(Self.releaseNotes)
        }
        XCTAssertTrue(present.isEmpty || present == locales, "release notes only in \(present)")
        for locale in present {
            let notes = try field(Self.releaseNotes, in: locale)
            XCTAssertFalse(notes.isEmpty, locale)
            XCTAssertLessThanOrEqual(notes.count, Self.releaseNotesLimit, locale)
        }
    }

    func testTheSharedFieldsAreFilledIn() throws {
        for name in Self.sharedFields {
            XCTAssertFalse(try field(name).isEmpty, name)
        }
    }

    func testTheURLsAreSecureAndThePrivacyPolicyIsInTheRepository() throws {
        for locale in try Self.locales {
            for name in Self.urlFields {
                let url = try XCTUnwrap(URL(string: field(name, in: locale)), "\(locale) \(name)")
                XCTAssertEqual(url.scheme, "https", "\(locale) \(name)")
            }
            let policy = try field("privacy_url", in: locale)
            XCTAssertTrue(policy.hasPrefix(Self.repositoryFilePrefix), locale)
            let path = String(policy.dropFirst(Self.repositoryFilePrefix.count))
            XCTAssertTrue(FileManager.default.fileExists(atPath: Self.repository.appendingPathComponent(path).path),
                          "\(locale): \(path) is not in the repository")
        }
    }

    func testKeywordsAreDistinctAndUnpadded() throws {
        for locale in try Self.locales {
            let keywords = try field("keywords", in: locale).split(separator: Self.keywordSeparator)
            XCTAssertEqual(Set(keywords).count, keywords.count, locale)
            // The space after a comma counts against the limit and adds nothing.
            XCTAssertTrue(keywords.allSatisfy { $0 == $0.trimmingCharacters(in: .whitespaces) }, locale)
        }
    }

    func testTheNameIsNotAKeyword() throws {
        // The store already matches the name; a keyword repeating it wastes the 100 characters.
        for locale in try Self.locales {
            let name = try field("name", in: locale).lowercased()
            let keywords = try field("keywords", in: locale).split(separator: Self.keywordSeparator)
            XCTAssertFalse(keywords.contains { $0.lowercased() == name }, locale)
        }
    }
}
