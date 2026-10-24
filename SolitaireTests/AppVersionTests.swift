import XCTest
@testable import Solitaire

/// The version App Store Connect accepts: three dot-separated numbers that the release tag
/// repeats (`v1.0.0`), and a whole build number that the release workflow raises on every upload.
final class AppVersionTests: XCTestCase {
    private static let versionComponentCount = 3
    private let info = Bundle(for: GameViewModel.self).infoDictionary ?? [:]

    func testTheVersionIsThreeNumbers() throws {
        let version = try XCTUnwrap(info["CFBundleShortVersionString"] as? String)
        let components = version.split(separator: ".", omittingEmptySubsequences: false)
        XCTAssertEqual(components.count, Self.versionComponentCount, version)
        XCTAssertTrue(components.allSatisfy { UInt($0) != nil }, version)
    }

    func testTheBuildNumberIsAWholeNumber() throws {
        let build = try XCTUnwrap(info["CFBundleVersion"] as? String)
        XCTAssertNotNil(UInt(build), build)
    }
}
