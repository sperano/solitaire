import XCTest
@testable import SolitaireKit

final class CodableTests: XCTestCase {
    private let seed: UInt64 = 99
    private static let balanceAboveBuyIn = 20

    private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func testFreshStateRoundTrips() throws {
        let state = GameState.deal(seed: seed, drawMode: .three)
        XCTAssertEqual(try roundTrip(state), state)
    }

    func testPlayedStateRoundTrips() throws {
        var state = GameState.deal(seed: seed, drawMode: .one)
        try state.apply(.draw)
        try state.apply(.draw)
        let decoded = try roundTrip(state)
        XCTAssertEqual(decoded, state)
        XCTAssertEqual(decoded.moveCount, 2)
    }

    func testGameWithHistoryRoundTrips() throws {
        var game = Game(seed: seed, drawMode: .one)
        try game.perform(.draw)
        try game.perform(.draw)
        let decoded = try roundTrip(game)
        XCTAssertEqual(decoded, game)
        XCTAssertEqual(decoded.history.count, 2)
    }

    func testDecodedGameCanUndo() throws {
        var game = Game(seed: seed, drawMode: .one)
        let start = game.state
        try game.perform(.draw)
        var decoded = try roundTrip(game)
        XCTAssertTrue(decoded.undo())
        XCTAssertEqual(decoded.state, start)
    }

    func testWhatCanBeRedoneSurvivesASave() throws {
        var game = Game(seed: seed, drawMode: .one)
        try game.perform(.draw)
        try game.perform(.draw)
        XCTAssertTrue(game.undo())
        var decoded = try roundTrip(game)
        XCTAssertEqual(decoded, game)
        XCTAssertTrue(decoded.redo())
        XCTAssertEqual(decoded.moveCount, 2)
    }

    func testSaveFromBeforeRedoLoadsWithNothingToRedo() throws {
        var game = Game(seed: seed, drawMode: .one)
        try game.perform(.draw)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
        XCTAssertNotNil(object.removeValue(forKey: "undone"))
        let decoded = try JSONDecoder().decode(Game.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(decoded.state, game.state)
        XCTAssertEqual(decoded.history, game.history)
        XCTAssertFalse(decoded.canRedo)
    }

    func testMovesAndPilesRoundTrip() throws {
        let moves: [Move] = [.draw, .move(from: .waste, to: .tableau(3), count: 1)]
        for move in moves { XCTAssertEqual(try roundTrip(move), move) }
        let piles: [PileID] = [.stock, .waste, .foundation(2), .tableau(6)]
        for pile in piles { XCTAssertEqual(try roundTrip(pile), pile) }
        for mode in DrawMode.allCases { XCTAssertEqual(try roundTrip(mode), mode) }
        for mode in ScoringMode.allCases { XCTAssertEqual(try roundTrip(mode), mode) }
    }

    func testCardFaceStateRoundTrips() throws {
        let up = card(.queen, .diamonds)
        XCTAssertEqual(try roundTrip(up), up)
        XCTAssertEqual(try roundTrip(up.faceDown()), up.faceDown())
    }

    private func jsonObject(_ state: GameState) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
    }

    private func decode(_ object: [String: Any]) throws -> GameState {
        try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: object))
    }

    func testDecodingRejectsMissingColumns() throws {
        var object = try jsonObject(.deal(seed: seed, drawMode: .one))
        object["tableau"] = Array((object["tableau"] as? [Any] ?? []).dropLast())
        XCTAssertThrowsError(try decode(object))
    }

    func testDecodingRejectsMissingFoundations() throws {
        var object = try jsonObject(.deal(seed: seed, drawMode: .one))
        object["foundations"] = Array((object["foundations"] as? [Any] ?? []).dropLast())
        XCTAssertThrowsError(try decode(object))
    }

    func testDecodingRejectsDuplicatedCards() throws {
        var object = try jsonObject(.deal(seed: seed, drawMode: .one))
        var stock = object["stock"] as? [Any] ?? []
        stock[0] = stock[1]
        object["stock"] = stock
        XCTAssertThrowsError(try decode(object))
    }

    func testScoredStateRoundTripsWithScoreAndRecycles() throws {
        let balance = Scoring.vegasBuyIn + Self.balanceAboveBuyIn
        var state = GameState.deal(seed: seed, drawMode: .three, scoringMode: .vegas, carriedBalance: balance)
        while !state.stock.isEmpty { try state.apply(.draw) }
        try state.apply(.draw)
        let decoded = try roundTrip(state)
        XCTAssertEqual(decoded, state)
        XCTAssertEqual(decoded.scoringMode, .vegas)
        XCTAssertEqual(decoded.score, Self.balanceAboveBuyIn)
        XCTAssertEqual(decoded.recycleCount, 1)
    }

    func testDecodingRejectsASaveWithOnlySomeScoringFields() throws {
        let state = GameState.deal(seed: seed, drawMode: .three, scoringMode: .vegas)
        for key in ["scoringMode", "score", "recycleCount"] {
            var object = try jsonObject(state)
            object.removeValue(forKey: key)
            XCTAssertThrowsError(try decode(object), "missing only \(key)")
        }
    }

    func testDecodingRejectsAScoreOutsideTheScoreRange() throws {
        for score in [Int.max, Int.min] {
            var object = try jsonObject(.deal(seed: seed, drawMode: .one, scoringMode: .vegas))
            object["score"] = score
            XCTAssertThrowsError(try decode(object), "\(score)")
        }
    }

    func testSaveFromBeforeScoringLoadsAsAnUnscoredGame() throws {
        var object = try jsonObject(.deal(seed: seed, drawMode: .one, scoringMode: .standard))
        for key in ["scoringMode", "score", "recycleCount"] {
            XCTAssertNotNil(object.removeValue(forKey: key), key)
        }
        let decoded = try decode(object)
        XCTAssertEqual(decoded.scoringMode, ScoringMode.none)
        XCTAssertEqual(decoded.score, 0)
        XCTAssertEqual(decoded.recycleCount, 0)
    }

    func testDecodingRejectsAnImpossibleScore() throws {
        var object = try jsonObject(.deal(seed: seed, drawMode: .one, scoringMode: .standard))
        object["score"] = -1
        XCTAssertThrowsError(try decode(object))
    }
}
