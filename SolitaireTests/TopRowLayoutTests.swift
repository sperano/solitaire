import XCTest
@testable import Solitaire

final class TopRowLayoutTests: XCTestCase {
    func testRightHandedPutsTheStockFirstAndFansTheWasteRight() {
        let layout = TopRowLayout(isLeftHanded: false)
        XCTAssertEqual(
            layout.slots,
            [.stock, .waste, .gap, .foundation(0), .foundation(1), .foundation(2), .foundation(3)]
        )
        XCTAssertEqual(layout.wasteFanDirection, 1)
    }

    func testLeftHandedPutsTheStockLastAndFansTheWasteLeft() {
        let layout = TopRowLayout(isLeftHanded: true)
        XCTAssertEqual(
            layout.slots,
            [.foundation(0), .foundation(1), .foundation(2), .foundation(3), .gap, .waste, .stock]
        )
        XCTAssertEqual(layout.wasteFanDirection, -1)
    }

    func testBothLayoutsFillTheSevenColumns() {
        for isLeftHanded in [false, true] {
            XCTAssertEqual(TopRowLayout(isLeftHanded: isLeftHanded).slots.count, BoardMetrics.columnCount)
        }
    }
}
