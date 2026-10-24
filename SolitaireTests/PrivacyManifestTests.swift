import XCTest
@testable import Solitaire

/// `PrivacyInfo.xcprivacy`: no tracking, no data collected, and a reason for every API Apple asks
/// one for. The App Privacy answers in App Store Connect ("Data Not Collected") must agree.
final class PrivacyManifestTests: XCTestCase {
    private static let manifestName = "PrivacyInfo"
    private static let manifestExtension = "xcprivacy"
    private static let repository = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent()
    /// The code that ships: the app and the engine, not the tests.
    private static let shippedSources = ["Solitaire", "SolitaireKit/Sources"]
    /// The reason each declared API is used, from Apple's list.
    private static let declaredReasons = [
        // CA92.1: settings read and written by the app itself.
        "NSPrivacyAccessedAPICategoryUserDefaults": ["CA92.1"],
    ]
    /// The symbols that put code in each required-reason category.
    private static let requiredReasonSymbols = [
        "NSPrivacyAccessedAPICategoryUserDefaults": ["UserDefaults", "AppStorage"],
        "NSPrivacyAccessedAPICategoryFileTimestamp": ["creationDate", "modificationDate", "ModificationDate"],
        "NSPrivacyAccessedAPICategorySystemBootTime": ["systemUptime", "mach_absolute_time"],
        "NSPrivacyAccessedAPICategoryDiskSpace": ["volumeAvailableCapacity", "systemFreeSize", "statfs"],
        "NSPrivacyAccessedAPICategoryActiveKeyboards": ["activeInputModes"],
    ]

    private func manifest() throws -> [String: Any] {
        let bundle = Bundle(for: GameViewModel.self)
        let url = try XCTUnwrap(
            bundle.url(forResource: Self.manifestName, withExtension: Self.manifestExtension),
            "the manifest is not in the app bundle"
        )
        let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil)
        return try XCTUnwrap(plist as? [String: Any])
    }

    func testTheAppNeitherTracksNorCollectsData() throws {
        let manifest = try manifest()
        XCTAssertEqual(manifest["NSPrivacyTracking"] as? Bool, false)
        XCTAssertEqual((manifest["NSPrivacyTrackingDomains"] as? [Any])?.count, 0)
        XCTAssertEqual((manifest["NSPrivacyCollectedDataTypes"] as? [Any])?.count, 0)
    }

    func testEveryRequiredReasonAPIIsDeclaredWithItsReason() throws {
        let entries = try XCTUnwrap(try manifest()["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        var declared: [String: [String]] = [:]
        for entry in entries {
            let category = try XCTUnwrap(entry["NSPrivacyAccessedAPIType"] as? String)
            declared[category] = try XCTUnwrap(entry["NSPrivacyAccessedAPITypeReasons"] as? [String])
        }
        XCTAssertEqual(declared, Self.declaredReasons)
    }

    /// A new use of a required-reason API fails here until the manifest declares it, and a
    /// declaration the code no longer needs fails too.
    func testTheDeclaredCategoriesAreTheOnesTheCodeUses() throws {
        let code = try Self.shippedSources.map(swiftSource).joined(separator: "\n")
        let used = Self.requiredReasonSymbols.filter { _, symbols in symbols.contains { code.contains($0) } }
        XCTAssertEqual(Set(used.keys), Set(Self.declaredReasons.keys))
    }

    private func swiftSource(under path: String) throws -> String {
        let root = Self.repository.appendingPathComponent(path)
        let files = try XCTUnwrap(FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil))
        return try files.compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" }
            .map { try String(contentsOf: $0, encoding: .utf8) }
            .joined(separator: "\n")
    }
}
