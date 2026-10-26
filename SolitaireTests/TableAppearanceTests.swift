import XCTest
@testable import Solitaire

final class TableAppearanceTests: XCTestCase {
    func testEveryCardBackHasItsOwnName() {
        let titles = CardBack.allCases.map(\.title)
        XCTAssertFalse(titles.contains(""))
        XCTAssertEqual(Set(titles).count, CardBack.allCases.count)
    }

    func testEveryFeltHasItsOwnName() {
        let titles = TableFelt.allCases.map(\.title)
        XCTAssertFalse(titles.contains(""))
        XCTAssertEqual(Set(titles).count, TableFelt.allCases.count)
    }

    /// Players who never open Settings keep the original look, which the icon and launch screen match.
    func testTheDefaultsAreTheOriginalLook() {
        XCTAssertEqual(CardBack.defaultValue, .blue)
        XCTAssertEqual(TableFelt.defaultValue, .green)
    }
}
