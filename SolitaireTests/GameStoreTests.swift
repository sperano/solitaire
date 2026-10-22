import SolitaireKit
import XCTest
@testable import Solitaire

@MainActor
final class GameStoreTests: XCTestCase {
    private static let seed: UInt64 = 7
    private static let elapsed = 123
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory.appending(path: "SolitaireTests-\(UUID().uuidString)")
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeSaved() throws -> SavedGame {
        var game = Game(seed: Self.seed, drawMode: .three)
        try game.perform(.draw)
        return SavedGame(game: game, elapsedSeconds: Self.elapsed)
    }

    func testFileStoreRoundTripsSavedGame() throws {
        let store = FileGameStore(url: directory.appending(path: "game.json"))
        let saved = try makeSaved()

        store.save(saved)

        XCTAssertEqual(store.load(), saved)
    }

    func testFileStoreReturnsNilWhenFileIsMissing() {
        XCTAssertNil(FileGameStore(url: directory.appending(path: "missing.json")).load())
    }

    func testSavingNilDeletesFile() throws {
        let url = directory.appending(path: "game.json")
        let store = FileGameStore(url: url)
        store.save(try makeSaved())
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        store.save(nil)

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        XCTAssertNil(store.load())
    }

    func testFileStoreCreatesIntermediateDirectories() throws {
        let url = directory.appending(path: "a/b/c/game.json")

        FileGameStore(url: url).save(try makeSaved())

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testInMemoryStoreHoldsWhatItWasGiven() throws {
        let saved = try makeSaved()
        XCTAssertNil(InMemoryGameStore().load())
        XCTAssertEqual(InMemoryGameStore(saved: saved).load(), saved)
    }

    func testInMemoryStoreSaveReplacesAndClears() throws {
        let store = InMemoryGameStore()
        let saved = try makeSaved()
        store.save(saved)
        XCTAssertEqual(store.load(), saved)
        store.save(nil)
        XCTAssertNil(store.load())
    }
}
