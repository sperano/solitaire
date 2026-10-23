import SolitaireKit
import XCTest
@testable import Solitaire

final class FlightPlannerTests: XCTestCase {
    private static let boardSize = CGSize(width: 390, height: 844)
    private static let tableauHeight: CGFloat = 500
    private static let columnStride: CGFloat = 52
    private let metrics = BoardMetrics(boardSize: boardSize)
    private let dealt = GameState.deal(seed: 42, drawMode: .one)

    private var planner: FlightPlanner {
        var frames: [PileID: CGRect] = [
            .stock: CGRect(origin: CGPoint(x: 8, y: 10), size: metrics.cardSize),
            .waste: CGRect(origin: CGPoint(x: 60, y: 10), size: metrics.cardSize),
        ]
        for (index, pile) in PileID.allFoundations.enumerated() {
            frames[pile] = CGRect(origin: CGPoint(x: 160 + CGFloat(index) * Self.columnStride, y: 10), size: metrics.cardSize)
        }
        for (index, pile) in PileID.allTableau.enumerated() {
            frames[pile] = CGRect(x: 8 + CGFloat(index) * Self.columnStride, y: 100, width: metrics.cardWidth, height: Self.tableauHeight)
        }
        return FlightPlanner(geometry: BoardGeometry(metrics: metrics, pileFrames: frames))
    }

    private func moveAce() throws -> GameState {
        var state = dealt
        try state.apply(.move(from: .tableau(6), to: .foundation(0), count: 1))
        return state
    }

    func testAMoveFliesFromTheCardToItsNewSlot() throws {
        let flights = planner.moves(from: dealt, to: try moveAce(), drop: nil)
        let flight = try XCTUnwrap(flights.first)
        XCTAssertEqual(flights.count, 1)
        XCTAssertEqual(flight.from, planner.geometry.frame(of: CardSlot(pile: .tableau(6), index: 6), in: dealt))
        XCTAssertEqual(flight.to, planner.geometry.frame(of: CardSlot(pile: .foundation(0), index: 0), in: try moveAce()))
        XCTAssertEqual(flight.delay, 0)
        XCTAssertEqual(flight.duration, FlightPlanner.moveSeconds)
    }

    func testADroppedCardStartsWhereItWasLetGo() throws {
        let translation = CGSize(width: 40, height: -120)
        let drop = DragInfo(source: .tableau(6), count: 1, translation: translation)
        let flight = try XCTUnwrap(planner.moves(from: dealt, to: try moveAce(), drop: drop).first)
        let slot = try XCTUnwrap(planner.geometry.frame(of: CardSlot(pile: .tableau(6), index: 6), in: dealt))
        XCTAssertEqual(flight.from, slot.offsetBy(dx: translation.width, dy: translation.height))
    }

    func testADropFromAnotherPileLeavesTheStartAlone() throws {
        let drop = DragInfo(source: .tableau(3), count: 1, translation: CGSize(width: 40, height: 40))
        let flight = try XCTUnwrap(planner.moves(from: dealt, to: try moveAce(), drop: drop).first)
        XCTAssertEqual(flight.from, planner.geometry.frame(of: CardSlot(pile: .tableau(6), index: 6), in: dealt))
    }

    func testTheDealLeavesTheStockRowByRow() throws {
        let flights = planner.deal(dealt)
        let stock = try XCTUnwrap(planner.geometry.frame(of: CardSlot(pile: .stock, index: 0), in: dealt))
        XCTAssertEqual(flights.count, GameState.tableauCardCount)
        XCTAssertTrue(flights.allSatisfy { $0.from == stock && !$0.before.isFaceUp && $0.duration == FlightPlanner.dealSeconds })
        // The first row goes across all seven columns before the second row starts.
        XCTAssertEqual(flights.prefix(GameState.tableauColumnCount).map(\.after.id), dealt.tableau.map { $0[0].id })
        XCTAssertEqual(flights.map(\.delay), (0 ..< flights.count).map { Double($0) * FlightPlanner.dealStaggerSeconds })
        XCTAssertEqual(flights.filter(\.after.isFaceUp).count, GameState.tableauColumnCount, "the top of each column lands face up")
    }

    func testNothingFliesBeforeThePilesAreLaidOut() throws {
        let planner = FlightPlanner(geometry: BoardGeometry(metrics: metrics, pileFrames: [:]))
        XCTAssertEqual(planner.deal(dealt), [])
        XCTAssertEqual(planner.moves(from: dealt, to: try moveAce(), drop: nil), [])
    }
}
