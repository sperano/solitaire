import SolitaireKit
import XCTest
@testable import Solitaire

@MainActor
final class StatisticsStoreTests: XCTestCase {
    private static let seconds = 150
    private static let moves = 100
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory.appending(path: "SolitaireTests-\(UUID().uuidString)")
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func sample() -> GameStatistics {
        var statistics = GameStatistics()
        statistics.recordWin(drawMode: .one, seconds: Self.seconds, moves: Self.moves)
        statistics.recordLoss(drawMode: .three)
        return statistics
    }

    func testFileStoreRoundTrips() {
        let store = FileStatisticsStore(url: directory.appending(path: "statistics.json"))
        store.save(sample())
        XCTAssertEqual(store.load(), sample())
    }

    func testFileStoreReturnsNilWhenFileIsMissing() {
        XCTAssertNil(FileStatisticsStore(url: directory.appending(path: "missing.json")).load())
    }

    func testUnreadableOrInconsistentFileLoadsAsNil() throws {
        let url = directory.appending(path: "statistics.json")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: url)
        XCTAssertNil(FileStatisticsStore(url: url).load())

        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(sample())) as? [String: Any])
        object["overall"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(StatisticsRecord()))
        try JSONSerialization.data(withJSONObject: object).write(to: url)
        XCTAssertNil(FileStatisticsStore(url: url).load(), "overall must match the draw modes")
    }

    func testInMemoryStoreHoldsWhatItWasGiven() {
        XCTAssertNil(InMemoryStatisticsStore().load())
        let store = InMemoryStatisticsStore(saved: sample())
        XCTAssertEqual(store.load(), sample())
        store.save(GameStatistics())
        XCTAssertEqual(store.load(), GameStatistics())
    }
}
