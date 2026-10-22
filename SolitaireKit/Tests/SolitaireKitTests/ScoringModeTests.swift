import XCTest
@testable import SolitaireKit

final class ScoringModeTests: XCTestCase {
    func testTitles() {
        XCTAssertEqual(ScoringMode.allCases.map(\.title), ["None", "Standard", "Vegas"])
    }

    func testRawValuesAreStableForPersistence() {
        XCTAssertEqual(ScoringMode.allCases.map(\.rawValue), [0, 1, 2])
    }
}
