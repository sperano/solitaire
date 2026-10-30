import SolitaireKit
import XCTest
@testable import Solitaire

@MainActor
final class BestScoresStoreTests: XCTestCase {
    private static let score = 4_200
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory.appending(path: "SolitaireTests-\(UUID().uuidString)")
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func sample() -> BestScores {
        var scores = BestScores()
        let win = BestScore(
            score: Self.score, drawMode: .one, moves: 100, seconds: 150, dealNumber: 42, wonAt: 1_800_000_000
        )
        scores.record(win, gameID: 1)
        return scores
    }

    func testFileStoreRoundTrips() {
        let store = FileBestScoresStore(url: directory.appending(path: "best-scores.json"))
        store.save(sample())
        XCTAssertEqual(store.load(), sample())
    }

    func testFileStoreReturnsNilWhenFileIsMissing() {
        XCTAssertNil(FileBestScoresStore(url: directory.appending(path: "missing.json")).load())
    }

    func testUnreadableFileLoadsAsNil() throws {
        let url = directory.appending(path: "best-scores.json")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: url)
        XCTAssertNil(FileBestScoresStore(url: url).load())
    }

    func testInMemoryStoreHoldsWhatItWasGiven() {
        XCTAssertNil(InMemoryBestScoresStore().load())
        let store = InMemoryBestScoresStore(saved: sample())
        XCTAssertEqual(store.load(), sample())
        store.save(BestScores())
        XCTAssertEqual(store.load(), BestScores())
    }
}
