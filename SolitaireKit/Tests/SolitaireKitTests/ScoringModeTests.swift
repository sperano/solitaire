import XCTest
@testable import SolitaireKit

final class ScoringModeTests: XCTestCase {
    func testRawValuesAreStableForPersistence() {
        XCTAssertEqual(ScoringMode.allCases.map(\.rawValue), [0, 1, 2])
    }
}
