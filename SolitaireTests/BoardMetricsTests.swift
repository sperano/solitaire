import CoreGraphics
import SolitaireKit
import XCTest
@testable import Solitaire

final class BoardMetricsTests: XCTestCase {
    private static let boardWidth: CGFloat = 400
    private static let accuracy: CGFloat = 0.0001
    private let metrics = BoardMetrics(boardWidth: boardWidth)

    private func cards(faceDown: Int, faceUp: Int) -> [Card] {
        let ranks = Rank.allCases
        let down = (0 ..< faceDown).map { Card(suit: .clubs, rank: ranks[$0]) }
        let up = (0 ..< faceUp).map { Card(suit: .hearts, rank: ranks[$0], isFaceUp: true) }
        return down + up
    }

    func testCardWidthDerivesFromPaddingAndSpacing() {
        let gaps = CGFloat(BoardMetrics.columnCount - 1) * BoardMetrics.columnSpacing
        let expected = (Self.boardWidth - 2 * BoardMetrics.horizontalPadding - gaps) / CGFloat(BoardMetrics.columnCount)
        XCTAssertEqual(metrics.cardWidth, expected, accuracy: Self.accuracy)
    }

    func testCardWidthNeverCollapsesBelowOne() {
        XCTAssertEqual(BoardMetrics(boardWidth: 0).cardWidth, 1)
    }

    func testCardHeightIsWidthTimesAspectRatio() {
        XCTAssertEqual(metrics.cardHeight, metrics.cardWidth * BoardMetrics.cardAspectRatio, accuracy: Self.accuracy)
        XCTAssertEqual(metrics.cardSize, CGSize(width: metrics.cardWidth, height: metrics.cardHeight))
    }

    func testColumnOffsetsForNoCardsIsEmpty() {
        XCTAssertEqual(metrics.columnOffsets(for: [], availableHeight: 1000), [])
    }

    func testColumnOffsetsForOneCardIsZero() {
        XCTAssertEqual(metrics.columnOffsets(for: cards(faceDown: 0, faceUp: 1), availableHeight: 1000), [0])
    }

    func testColumnOffsetsUseFaceDownAndFaceUpStepsWhenThereIsRoom() {
        let offsets = metrics.columnOffsets(for: cards(faceDown: 2, faceUp: 2), availableHeight: 10000)
        XCTAssertEqual(offsets.count, 4)
        XCTAssertEqual(offsets[0], 0, accuracy: Self.accuracy)
        XCTAssertEqual(offsets[1], metrics.faceDownOffset, accuracy: Self.accuracy)
        XCTAssertEqual(offsets[2], 2 * metrics.faceDownOffset, accuracy: Self.accuracy)
        XCTAssertEqual(offsets[3], 2 * metrics.faceDownOffset + metrics.faceUpOffset, accuracy: Self.accuracy)
    }

    func testColumnOffsetsCompressToFitAvailableHeight() {
        let column = cards(faceDown: 3, faceUp: 10)
        let availableHeight = metrics.cardHeight * 3
        let offsets = metrics.columnOffsets(for: column, availableHeight: availableHeight)

        XCTAssertEqual(offsets.count, column.count)
        XCTAssertEqual(offsets.last! + metrics.cardHeight, availableHeight, accuracy: Self.accuracy)
        // Proportional: the face-up/face-down step ratio is preserved.
        let downStep = offsets[1] - offsets[0]
        let upStep = offsets[4] - offsets[3]
        XCTAssertEqual(upStep / downStep, BoardMetrics.faceUpOffsetRatio / BoardMetrics.faceDownOffsetRatio, accuracy: Self.accuracy)
    }

    func testColumnOffsetsWithNoRoomStackAllCardsOnTop() {
        let offsets = metrics.columnOffsets(for: cards(faceDown: 2, faceUp: 2), availableHeight: 0)
        XCTAssertEqual(offsets, [0, 0, 0, 0])
    }
}
