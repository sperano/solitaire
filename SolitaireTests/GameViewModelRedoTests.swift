import SolitaireKit
import XCTest
@testable import Solitaire

/// Redo in `GameViewModel`: a move taken back by undo is played again, with everything a move
/// does. Kept apart from `GameViewModelTests` so neither file outgrows the size limit.
@MainActor
final class GameViewModelRedoTests: XCTestCase {
    private static let fixedSeed: UInt64 = 99
    private static let winningSeconds = 245

    private var suiteName = ""
    private var defaults: UserDefaults!
    private var settings: GameSettings!
    private var store: InMemoryGameStore!
    private var statisticsStore: InMemoryStatisticsStore!
    private var spy: HapticsSpy!

    override func setUp() async throws {
        suiteName = "quebec.spe.SolitaireTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        settings = GameSettings(defaults: defaults)
        store = InMemoryGameStore()
        statisticsStore = InMemoryStatisticsStore()
        spy = HapticsSpy()
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private func makeModel(resuming game: Game? = nil) -> GameViewModel {
        if let game { store = InMemoryGameStore(saved: SavedGame(game: game, elapsedSeconds: Self.winningSeconds)) }
        return GameViewModel(
            store: store, settings: settings, statistics: StatisticsModel(store: statisticsStore),
            haptics: spy, fixedSeed: Self.fixedSeed
        )
    }

    /// Wins the game by tapping the one card left in the tableau.
    private func playLastMove(_ model: GameViewModel) throws {
        let column = try XCTUnwrap(PileID.allTableau.first { !model.state.pile($0).isEmpty })
        model.tapCard(in: column, index: model.state.pile(column).count - 1)
    }

    private var recorded: GameStatistics { statisticsStore.saved ?? GameStatistics() }

    func testRedoIsOfferedOnlyAfterAnUndo() {
        let model = makeModel()
        XCTAssertFalse(model.canRedo)
        model.draw()
        XCTAssertFalse(model.canRedo)
        model.undo()
        XCTAssertTrue(model.canRedo)
    }

    func testRedoPlaysTheMoveAgainAndSavesIt() {
        let model = makeModel()
        model.draw()
        let afterDraw = model.state
        model.undo()

        model.redo()

        XCTAssertEqual(model.state, afterDraw)
        XCTAssertFalse(model.canRedo)
        XCTAssertTrue(model.canUndo)
        XCTAssertEqual(store.saved?.game, model.game)
    }

    func testRedoWithNothingUndoneChangesNothing() {
        let model = makeModel()
        model.draw()
        let game = model.game
        model.redo()
        XCTAssertEqual(model.game, game)
    }

    func testANewMoveOrGameEndsRedo() {
        let model = makeModel()
        model.draw()
        model.undo()
        model.draw()
        XCTAssertFalse(model.canRedo)

        model.undo()
        model.newGame()
        XCTAssertFalse(model.canRedo)
    }

    func testRedoClearsTheHintAndIsFelt() {
        let model = makeModel()
        model.draw()
        model.undo()
        model.showHint()
        let before = spy.played

        model.redo()

        XCTAssertNil(model.hint)
        XCTAssertEqual(spy.played, before + [.move])
    }

    func testRedoingTheWinningMoveWinsAndCountsTheWinOnce() throws {
        let model = makeModel(resuming: try Game.oneMoveFromWinning())
        try playLastMove(model)
        model.undo()
        XCTAssertFalse(model.isWon)

        model.redo()

        XCTAssertTrue(model.isWon)
        XCTAssertEqual(spy.played.last, .win)
        XCTAssertEqual(recorded.overall.won, 1)
        XCTAssertEqual(recorded.overall.played, 1)
    }
}
