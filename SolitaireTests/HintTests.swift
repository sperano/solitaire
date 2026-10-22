import SolitaireKit
import XCTest
@testable import Solitaire

@MainActor
final class HintTests: XCTestCase {
    private static let seed: UInt64 = 42
    private static let seedSearchRange: ClosedRange<UInt64> = 0 ... 500
    private static let shortHintDuration = Duration.milliseconds(50)
    private static let waitLimit = Duration.seconds(5)

    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() async throws {
        suiteName = "quebec.spe.SolitaireTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private func makeModel(seed: UInt64 = HintTests.seed, resuming game: Game? = nil) -> GameViewModel {
        GameViewModel(
            store: InMemoryGameStore(saved: game.map { SavedGame(game: $0, elapsedSeconds: 0) }),
            settings: GameSettings(defaults: defaults),
            statistics: StatisticsModel(store: InMemoryStatisticsStore()),
            fixedSeed: seed
        )
    }

    /// First deal whose suggested move satisfies `matches`.
    private func modelSuggesting(_ matches: (Move) -> Bool) throws -> GameViewModel {
        for seed in Self.seedSearchRange {
            if let move = Game(seed: seed, drawMode: .one).suggestedMove(), matches(move) {
                return makeModel(seed: seed)
            }
        }
        throw XCTSkip("no deal in range suggests such a move")
    }

    private func waitUntil(_ condition: () -> Bool) async {
        let deadline = ContinuousClock.now + Self.waitLimit
        while !condition(), ContinuousClock.now < deadline {
            await Task.yield()
        }
    }

    /// First deal that, drawn through to an empty stock, has nothing better to do than recycle.
    private func modelWithEmptyStockSuggestingRecycle() throws -> GameViewModel {
        for seed in Self.seedSearchRange {
            let model = makeModel(seed: seed)
            while !model.state.stock.isEmpty { model.draw() }
            if model.game.suggestedMove() == .draw { return model }
        }
        throw XCTSkip("no deal in range ends its first pass with only the recycle")
    }

    // MARK: Showing and clearing

    func testShowHintShowsTheEngineSuggestion() throws {
        let model = makeModel()
        model.showHint()
        let move = try XCTUnwrap(model.game.suggestedMove())
        XCTAssertEqual(model.hint, .move(move))
    }

    func testNoUsefulMoveOnADeadlockedBoard() {
        let model = makeModel(resuming: Game(state: FixturePosition.deadlocked.state()))
        XCTAssertTrue(model.canHint)
        model.showHint()
        XCTAssertEqual(model.hint, .noUsefulMove)
    }

    func testAMoveClearsTheHint() {
        let model = makeModel()
        model.showHint()
        model.draw()
        XCTAssertNil(model.hint)
    }

    func testUndoClearsTheHint() {
        let model = makeModel()
        model.draw()
        model.showHint()
        model.undo()
        XCTAssertNil(model.hint)
    }

    func testNewGameClearsTheHint() {
        let model = makeModel()
        model.showHint()
        model.newGame()
        XCTAssertNil(model.hint)
    }

    func testAnIllegalDropKeepsTheHint() {
        let model = makeModel()
        model.showHint()
        model.drag = DragInfo(source: .tableau(0), count: 1, translation: .zero)
        XCTAssertFalse(model.drop(on: .foundation(0)))
        XCTAssertNotNil(model.hint)
    }

    func testTheHintGoesAwayByItself() async {
        let model = makeModel()
        model.hintDuration = Self.shortHintDuration
        model.showHint()
        XCTAssertNotNil(model.hint)
        await waitUntil { model.hint == nil }
        XCTAssertNil(model.hint)
    }

    func testAnOldTimerDoesNotClearANewerHint() async {
        let model = makeModel()
        model.hintDuration = Self.shortHintDuration
        model.showHint()
        model.hintDuration = Self.waitLimit
        model.showHint()
        try? await Task.sleep(for: Self.shortHintDuration * 4)
        XCTAssertNotNil(model.hint, "the first hint's timer was cancelled")
    }

    // MARK: When hints are offered

    func testNoHintOnceTheGameIsWon() throws {
        let model = makeModel(resuming: try Game.won())
        XCTAssertFalse(model.canHint)
        model.showHint()
        XCTAssertNil(model.hint)
    }

    func testNoHintWhileFinishIsOffered() {
        let model = makeModel(resuming: Game.completable())
        XCTAssertTrue(model.canAutoComplete)
        XCTAssertFalse(model.canHint)
    }

    // MARK: Highlights

    func testFoundationHintHighlightsTheCardAndTheEmptyFoundation() throws {
        let model = try modelSuggesting {
            if case let .move(from, to, _) = $0 { return from.isTableau && to.isFoundation }
            return false
        }
        model.showHint()
        guard case let .move(.move(from, to, _)) = model.hint else { return XCTFail("expected a move hint") }
        let top = model.state.pile(from).count - 1

        XCTAssertTrue(model.isHinted(from, index: top))
        XCTAssertTrue(model.isHintedEmptySlot(to))
        XCTAssertFalse(model.isHinted(from, index: top - 1), "the card underneath stays put")
        XCTAssertFalse(model.isStockHinted)
        for other in PileID.allTableau where other != from {
            XCTAssertFalse(model.isHinted(other, index: model.state.pile(other).count - 1))
        }
    }

    func testTableauHintHighlightsTheRunAndTheCardItLandsOn() throws {
        let model = try modelSuggesting {
            if case let .move(from, to, _) = $0 { return from.isTableau && to.isTableau }
            return false
        }
        model.showHint()
        guard case let .move(.move(from, to, count)) = model.hint else { return XCTFail("expected a move hint") }
        let fromCount = model.state.pile(from).count
        let toCount = model.state.pile(to).count

        for index in fromCount - count ..< fromCount {
            XCTAssertTrue(model.isHinted(from, index: index))
        }
        XCTAssertFalse(model.isHinted(from, index: fromCount - count - 1))
        XCTAssertTrue(model.isHinted(to, index: toCount - 1))
        XCTAssertFalse(model.isHintedEmptySlot(to))
    }

    func testDrawHintHighlightsTheStock() throws {
        let model = try modelSuggesting { $0 == .draw }
        model.showHint()
        XCTAssertTrue(model.isStockHinted)
        XCTAssertTrue(model.isHinted(.stock, index: model.state.stock.count - 1))
        XCTAssertFalse(model.isHintedEmptySlot(.stock))
    }

    func testRecycleHintHighlightsTheEmptyStock() throws {
        let model = try modelWithEmptyStockSuggestingRecycle()
        model.showHint()
        XCTAssertTrue(model.isStockHinted)
        XCTAssertTrue(model.isHintedEmptySlot(.stock))
    }

    func testNothingIsHighlightedWithoutAHint() {
        let model = makeModel()
        for pile in PileID.allTableau + PileID.allFoundations + [.stock, .waste] {
            XCTAssertFalse(model.isHinted(pile, index: model.state.pile(pile).count - 1))
            XCTAssertFalse(model.isHintedEmptySlot(pile))
        }
        XCTAssertFalse(model.isStockHinted)
    }

    func testNoUsefulMoveHighlightsNothing() {
        let model = makeModel(resuming: Game(state: FixturePosition.deadlocked.state()))
        model.showHint()
        for pile in PileID.allTableau {
            XCTAssertFalse(model.isHinted(pile, index: model.state.pile(pile).count - 1))
        }
        XCTAssertFalse(model.isStockHinted)
    }
}
