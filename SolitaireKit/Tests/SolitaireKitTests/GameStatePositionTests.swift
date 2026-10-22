import XCTest
@testable import SolitaireKit

final class GameStatePositionTests: XCTestCase {
    private static let standardScore = 50
    private static let moveCount = 12

    private let wonFoundations = Suit.allCases.map(fullSuit)

    func testBuildsTheGivenPilesAndFillsTheRest() throws {
        let waste = fullSuit(.diamonds)
        let foundations = [fullSuit(.clubs), Array(fullSuit(.hearts).dropLast()), Array(fullSuit(.spades).dropLast())]
        let tableau = [[card(.king, .hearts)], [card(.king, .spades)]]
        let state = try XCTUnwrap(GameState.position(
            waste: waste, foundations: foundations, tableau: tableau, drawMode: .three,
            scoringMode: .standard, score: Self.standardScore, moveCount: Self.moveCount
        ))

        XCTAssertEqual(state.waste, waste)
        XCTAssertEqual(Array(state.foundations.prefix(foundations.count)), foundations)
        XCTAssertEqual(state.foundations.last, [])
        XCTAssertEqual(state.foundations.count, GameState.foundationCount)
        XCTAssertEqual(Array(state.tableau.prefix(tableau.count)), tableau)
        XCTAssertEqual(state.tableau.count, GameState.tableauColumnCount)
        XCTAssertTrue(state.stock.isEmpty)
        XCTAssertEqual(state.drawMode, .three)
        XCTAssertEqual(state.scoringMode, .standard)
        XCTAssertEqual(state.score, Self.standardScore)
        XCTAssertEqual(state.moveCount, Self.moveCount)
        XCTAssertEqual(state.recycleCount, 0)
    }

    func testAWonBoardIsAPosition() throws {
        XCTAssertTrue(try XCTUnwrap(GameState.position(foundations: wonFoundations)).isWon)
    }

    func testRejectsAnIncompleteDeck() {
        XCTAssertNil(GameState.position(foundations: Array(wonFoundations.dropLast())))
    }

    func testRejectsTooManyPiles() {
        XCTAssertNil(GameState.position(foundations: wonFoundations + [[]]))
        XCTAssertNil(GameState.position(
            foundations: wonFoundations, tableau: Array(repeating: [], count: GameState.tableauColumnCount + 1)
        ))
    }

    func testRejectsAnImpossiblePosition() {
        var foundations = wonFoundations
        foundations[0].reverse()
        XCTAssertNil(GameState.position(foundations: foundations), "foundations build up from the ace")
        XCTAssertNil(GameState.position(foundations: wonFoundations, scoringMode: .none, score: Self.standardScore))
    }
}
