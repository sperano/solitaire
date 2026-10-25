import SolitaireKit
import XCTest
@testable import Solitaire

final class BoardGeometryTests: XCTestCase {
    private static let boardSize = CGSize(width: 390, height: 844)
    private static let tableauHeight: CGFloat = 500
    private static let tolerance: CGFloat = 0.001
    private let metrics = BoardMetrics(boardSize: boardSize)

    private var pileFrames: [PileID: CGRect] {
        let size = metrics.cardSize
        var frames: [PileID: CGRect] = [
            .stock: CGRect(origin: CGPoint(x: 8, y: 10), size: size),
            .waste: CGRect(origin: CGPoint(x: 60, y: 10), size: size),
        ]
        for (index, pile) in PileID.allFoundations.enumerated() {
            frames[pile] = CGRect(x: 160 + CGFloat(index) * 52, y: 10, width: size.width, height: size.height)
        }
        for (index, pile) in PileID.allTableau.enumerated() {
            frames[pile] = CGRect(x: 8 + CGFloat(index) * 52, y: 100, width: size.width, height: Self.tableauHeight)
        }
        return frames
    }

    private var geometry: BoardGeometry { BoardGeometry(metrics: metrics, pileFrames: pileFrames) }

    func testStockAndFoundationCardsSitOnThePile() throws {
        let state = GameState.deal(seed: 42, drawMode: .one)
        for pile in [PileID.stock, .foundation(2)] {
            let frame = try XCTUnwrap(geometry.frame(of: CardSlot(pile: pile, index: 0), in: state))
            XCTAssertEqual(frame.origin, pileFrames[pile]?.origin)
            XCTAssertEqual(frame.size, metrics.cardSize)
        }
    }

    func testTableauCardsFollowTheColumnOffsets() throws {
        let state = GameState.deal(seed: 42, drawMode: .one)
        let column = PileID.tableau(4)
        let offsets = metrics.columnOffsets(for: state.pile(column), availableHeight: Self.tableauHeight)
        for index in offsets.indices {
            let frame = try XCTUnwrap(geometry.frame(of: CardSlot(pile: column, index: index), in: state))
            XCTAssertEqual(frame.minY, (pileFrames[column]?.minY ?? 0) + offsets[index], accuracy: Self.tolerance)
        }
    }

    func testWasteCardsFanOutOnlyForTheVisibleOnes() throws {
        var state = GameState.deal(seed: 42, drawMode: .three)
        try state.apply(.draw)
        try state.apply(.draw)
        let wasteX = try XCTUnwrap(pileFrames[.waste]?.minX)
        let xs = try (0 ..< state.waste.count).map {
            try XCTUnwrap(geometry.frame(of: CardSlot(pile: .waste, index: $0), in: state)).minX - wasteX
        }
        // Six cards, the top three fanned, the rest stacked under the first of them.
        let expected = [0, 0, 0, 0, metrics.wasteFanOffset, 2 * metrics.wasteFanOffset]
        XCTAssertEqual(xs.count, expected.count)
        for (actual, wanted) in zip(xs, expected) {
            XCTAssertEqual(actual, wanted, accuracy: Self.tolerance)
        }
        XCTAssertEqual(BoardGeometry.visibleWasteCount(in: state), DrawMode.three.cardsPerDraw)
    }

    func testLeftHandedWasteFansToTheLeft() throws {
        var state = GameState.deal(seed: 42, drawMode: .three)
        try state.apply(.draw)
        let mirrored = BoardGeometry(metrics: metrics, pileFrames: pileFrames, topRow: TopRowLayout(isLeftHanded: true))
        let wasteX = try XCTUnwrap(pileFrames[.waste]?.minX)
        let xs = try (0 ..< state.waste.count).map {
            try XCTUnwrap(mirrored.frame(of: CardSlot(pile: .waste, index: $0), in: state)).minX - wasteX
        }
        let expected = [0, -metrics.wasteFanOffset, -2 * metrics.wasteFanOffset]
        XCTAssertEqual(xs.count, expected.count)
        for (actual, wanted) in zip(xs, expected) {
            XCTAssertEqual(actual, wanted, accuracy: Self.tolerance)
        }
    }

    func testNoFrameBeforeThePileIsLaidOut() {
        let geometry = BoardGeometry(metrics: metrics, pileFrames: [:])
        XCTAssertNil(geometry.frame(of: CardSlot(pile: .stock, index: 0), in: GameState.deal(seed: 1, drawMode: .one)))
    }
}
