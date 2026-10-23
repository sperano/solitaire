import CoreGraphics
import SolitaireKit
import XCTest
@testable import Solitaire

final class BoardMetricsTests: XCTestCase {
    private static let boardWidth: CGFloat = 400
    /// Tall enough that the width, not the height, sets the card size.
    private static let boardHeight: CGFloat = 2000
    private static let accuracy: CGFloat = 0.0001
    private let metrics = BoardMetrics(boardSize: CGSize(width: boardWidth, height: boardHeight))

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
        XCTAssertEqual(BoardMetrics(boardSize: .zero).cardWidth, 1)
    }

    func testAShortBoardLimitsTheCardsByItsHeight() {
        let landscape = BoardMetrics(boardSize: CGSize(width: 874, height: 330))
        let rows = 330 - BoardMetrics.verticalGapCount * BoardMetrics.rowSpacing
        let expectedHeight = rows / (1 + BoardMetrics.tableauCardHeights)
        XCTAssertEqual(landscape.cardHeight, expectedHeight, accuracy: Self.accuracy)
        XCTAssertLessThan(landscape.cardWidth, BoardMetrics(boardSize: CGSize(width: 874, height: Self.boardHeight)).cardWidth)
    }

    func testTheHeightLimitLeavesTheTableauItsShareOfTheBoard() {
        let landscape = BoardMetrics(boardSize: CGSize(width: 874, height: 330))
        let tableau = landscape.tableauHeight(boardHeight: 330)
        XCTAssertEqual(tableau, landscape.cardHeight * BoardMetrics.tableauCardHeights, accuracy: Self.accuracy)
        // The deal's longest column fits without compression.
        let deal = cards(faceDown: 6, faceUp: 1)
        let offsets = landscape.columnOffsets(for: deal, availableHeight: tableau)
        XCTAssertEqual(offsets.last!, 6 * landscape.faceDownOffset, accuracy: Self.accuracy)
    }

    func testATallBoardGivesTheTableauWhatTheTopRowLeaves() {
        let tableau = metrics.tableauHeight(boardHeight: Self.boardHeight)
        let expected = Self.boardHeight - metrics.cardHeight - BoardMetrics.verticalGapCount * BoardMetrics.rowSpacing
        XCTAssertEqual(tableau, expected, accuracy: Self.accuracy)
    }

    func testTheTableauIsNeverShorterThanACard() {
        XCTAssertEqual(metrics.tableauHeight(boardHeight: 0), metrics.cardHeight, accuracy: Self.accuracy)
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
