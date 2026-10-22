import CoreGraphics
import SolitaireKit
import XCTest
@testable import Solitaire

final class DragInfoTests: XCTestCase {
    private static let pileCount = 6
    private static let dragCount = 3
    private let drag = DragInfo(source: .tableau(2), count: dragCount, translation: .zero)

    func testCoversTopCountCardsOfSourcePile() {
        for index in (Self.pileCount - Self.dragCount) ..< Self.pileCount {
            XCTAssertTrue(drag.covers(pile: .tableau(2), index: index, pileCount: Self.pileCount))
        }
    }

    func testDoesNotCoverLowerIndices() {
        for index in 0 ..< (Self.pileCount - Self.dragCount) {
            XCTAssertFalse(drag.covers(pile: .tableau(2), index: index, pileCount: Self.pileCount))
        }
    }

    func testDoesNotCoverOtherPiles() {
        let top = Self.pileCount - 1
        XCTAssertFalse(drag.covers(pile: .tableau(3), index: top, pileCount: Self.pileCount))
        XCTAssertFalse(drag.covers(pile: .waste, index: top, pileCount: Self.pileCount))
        XCTAssertFalse(drag.covers(pile: .foundation(2), index: top, pileCount: Self.pileCount))
    }
}
