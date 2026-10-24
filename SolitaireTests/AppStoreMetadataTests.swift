import XCTest

/// The App Store text under `AppStore/metadata/<locale>/`, one file per App Store Connect field
/// (the layout fastlane deliver reads): every locale has every field, within the store's limits.
final class AppStoreMetadataTests: XCTestCase {
    private static let metadata = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("AppStore/metadata")
    private static let locales = ["en-US", "fr-CA"]
    /// App Store Connect's limits, in characters.
    private static let limits = [
        "name": 30,
        "subtitle": 30,
        "promotional_text": 170,
        "keywords": 100,
        "description": 4_000,
    ]
    private static let keywordSeparator: Character = ","

    private func field(_ name: String, in locale: String) throws -> String {
        let url = Self.metadata.appendingPathComponent(locale).appendingPathComponent("\(name).txt")
        return try String(contentsOf: url, encoding: .utf8).trimmingCharacters(in: .newlines)
    }

    func testEveryLocaleHasEveryFieldWithinItsLimit() throws {
        for locale in Self.locales {
            for (name, limit) in Self.limits {
                let text = try field(name, in: locale)
                XCTAssertFalse(text.isEmpty, "\(locale) \(name)")
                XCTAssertLessThanOrEqual(text.count, limit, "\(locale) \(name)")
            }
        }
    }

    func testThereAreNoOtherLocalesOrFields() throws {
        let manager = FileManager.default
        let locales = try manager.contentsOfDirectory(atPath: Self.metadata.path).filter { !$0.hasPrefix(".") }
        XCTAssertEqual(locales.sorted(), Self.locales)
        for locale in Self.locales {
            let files = try manager.contentsOfDirectory(atPath: Self.metadata.appendingPathComponent(locale).path)
            XCTAssertEqual(files.sorted(), Self.limits.keys.map { "\($0).txt" }.sorted(), locale)
        }
    }

    func testKeywordsAreDistinctAndUnpadded() throws {
        for locale in Self.locales {
            let keywords = try field("keywords", in: locale).split(separator: Self.keywordSeparator)
            XCTAssertEqual(Set(keywords).count, keywords.count, locale)
            // The space after a comma counts against the limit and adds nothing.
            XCTAssertTrue(keywords.allSatisfy { $0 == $0.trimmingCharacters(in: .whitespaces) }, locale)
        }
    }

    func testTheNameIsNotAKeyword() throws {
        // The store already matches the name; a keyword repeating it wastes the 100 characters.
        for locale in Self.locales {
            let name = try field("name", in: locale).lowercased()
            let keywords = try field("keywords", in: locale).split(separator: Self.keywordSeparator)
            XCTAssertFalse(keywords.contains { $0.lowercased() == name }, locale)
        }
    }
}
