import XCTest
@testable import SolitaireKit

final class CodableTests: XCTestCase {
    private let seed: UInt64 = 99

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

    func testMovesAndPilesRoundTrip() throws {
        let moves: [Move] = [.draw, .move(from: .waste, to: .tableau(3), count: 1)]
        for move in moves { XCTAssertEqual(try roundTrip(move), move) }
        let piles: [PileID] = [.stock, .waste, .foundation(2), .tableau(6)]
        for pile in piles { XCTAssertEqual(try roundTrip(pile), pile) }
        for mode in DrawMode.allCases { XCTAssertEqual(try roundTrip(mode), mode) }
    }

    func testCardFaceStateRoundTrips() throws {
        let up = card(.queen, .diamonds)
        XCTAssertEqual(try roundTrip(up), up)
        XCTAssertEqual(try roundTrip(up.faceDown()), up.faceDown())
    }
}
