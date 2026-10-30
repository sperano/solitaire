import SolitaireKit
import XCTest
@testable import Solitaire

/// How `GameViewModel` reports results to the statistics. Kept apart from `GameViewModelTests`
/// so neither file outgrows the size limit.
@MainActor
final class GameViewModelStatisticsTests: XCTestCase {
    private static let fixedSeed: UInt64 = 99
    private static let winningSeconds = 245

    private var suiteName = ""
    private var defaults: UserDefaults!
    private var settings: GameSettings!
    private var store: InMemoryGameStore!
    private var statisticsStore: InMemoryStatisticsStore!
    private var bestScoresStore: InMemoryBestScoresStore!

    override func setUp() async throws {
        suiteName = "quebec.spe.SolitaireTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        settings = GameSettings(defaults: defaults)
        store = InMemoryGameStore()
        statisticsStore = InMemoryStatisticsStore()
        bestScoresStore = InMemoryBestScoresStore()
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private func makeModel() -> GameViewModel {
        GameViewModel(
            store: store, settings: settings, statistics: StatisticsModel(
                store: statisticsStore,
                bestScoresStore: bestScoresStore
            ),
            fixedSeed: Self.fixedSeed
        )
    }

    private func makeModel(resuming saved: SavedGame) -> GameViewModel {
        store = InMemoryGameStore(saved: saved)
        return makeModel()
    }

    /// Wins the game by tapping the one card left in the tableau.
    private func playLastMove(_ model: GameViewModel) throws {
        let column = try XCTUnwrap(PileID.allTableau.first { !model.state.pile($0).isEmpty })
        model.tapCard(in: column, index: model.state.pile(column).count - 1)
    }

    private var recorded: GameStatistics { statisticsStore.saved ?? GameStatistics() }
    private var bestScores: BestScores { bestScoresStore.saved ?? BestScores() }

    // MARK: Losses

    func testAbandoningAnUntouchedDealRecordsNothing() {
        let model = makeModel()
        model.newGame()
        XCTAssertEqual(recorded.overall.played, 0)
    }

    func testAbandoningAStartedGameCountsAsALossForItsDrawMode() {
        settings.drawMode = .three
        let model = makeModel()
        model.draw()
        settings.drawMode = .one

        model.newGame()

        XCTAssertEqual(recorded[.three].played, 1)
        XCTAssertEqual(recorded[.three].won, 0)
        XCTAssertEqual(recorded[.one].played, 0, "the loss belongs to the abandoned game's mode")
        XCTAssertEqual(recorded.overall.played, 1)
    }

    func testUndoingBackToTheDealStillCountsAsALoss() {
        let model = makeModel()
        model.draw()
        model.undo()
        XCTAssertEqual(model.moveCount, 0)

        model.newGame()

        XCTAssertEqual(recorded.overall.played, 1)
    }

    func testOnlyTheAbandonedGameIsCounted() {
        let model = makeModel()
        model.draw()
        model.newGame()
        model.newGame()
        XCTAssertEqual(recorded.overall.played, 1, "the second deal was never started")
    }

    func testStartedFlagSurvivesARelaunch() throws {
        let first = makeModel()
        first.draw()
        first.undo()
        let saved = try XCTUnwrap(store.saved)
        XCTAssertTrue(saved.isStarted)

        makeModel(resuming: saved).newGame()

        XCTAssertEqual(recorded.overall.played, 1)
    }

    // MARK: Wins

    func testWinningRecordsTimeAndMoves() throws {
        let game = try Game.oneMoveFromWinning()
        let model = makeModel(resuming: SavedGame(game: game, elapsedSeconds: Self.winningSeconds))

        try playLastMove(model)

        XCTAssertTrue(model.isWon)
        XCTAssertEqual(recorded[.one].won, 1)
        XCTAssertEqual(recorded[.one].bestTimeSeconds, Self.winningSeconds)
        XCTAssertEqual(recorded[.one].fewestMoves, model.moveCount)
        XCTAssertEqual(recorded.overall.currentStreak, 1)
        XCTAssertEqual(store.saved?.isResultRecorded, true)
    }

    func testNewGameAfterAWinDoesNotAddALoss() throws {
        let model = makeModel(resuming: SavedGame(
            game: try Game.oneMoveFromWinning(),
            elapsedSeconds: Self.winningSeconds
        ))
        try playLastMove(model)

        model.newGame()

        XCTAssertEqual(recorded.overall.played, 1)
        XCTAssertEqual(recorded.overall.won, 1)
    }

    func testAWinIsCountedOnceEvenIfUndoneAndReplayed() throws {
        let model = makeModel(resuming: SavedGame(
            game: try Game.oneMoveFromWinning(),
            elapsedSeconds: Self.winningSeconds
        ))
        try playLastMove(model)
        model.undo()
        XCTAssertFalse(model.isWon)
        try playLastMove(model)

        XCTAssertEqual(recorded.overall.won, 1)
        XCTAssertEqual(recorded.overall.played, 1)
    }

    func testReplayingAWinFromAStaleSaveDoesNotCountItAgain() throws {
        // The statistics were written but the game file still holds the position before the
        // winning move, as if the app died between the two writes.
        let beforeWin = SavedGame(game: try Game.oneMoveFromWinning(), elapsedSeconds: Self.winningSeconds)
        try playLastMove(makeModel(resuming: beforeWin))
        XCTAssertEqual(recorded.overall.won, 1)

        try playLastMove(makeModel(resuming: beforeWin))

        XCTAssertEqual(recorded.overall.won, 1)
        XCTAssertEqual(recorded.overall.played, 1)
    }

    func testAutoCompleteWinIsRecorded() async {
        let model = makeModel(resuming: SavedGame(game: Game.completable(), elapsedSeconds: Self.winningSeconds))
        model.autoComplete()
        let deadline = ContinuousClock.now + .seconds(10)
        while model.isAutoCompleting, ContinuousClock.now < deadline {
            await Task.yield()
        }
        XCTAssertTrue(model.isWon)
        XCTAssertEqual(recorded.overall.won, 1)
    }

    // MARK: Best scores

    func testAStandardWinIsRankedWithItsTimeBonus() throws {
        let game = try Game.oneMoveFromWinning(scoringMode: .standard, drawMode: .three)
        let model = makeModel(resuming: SavedGame(game: game, elapsedSeconds: Self.winningSeconds))

        try playLastMove(model)

        let best = try XCTUnwrap(bestScores[.three].first)
        XCTAssertGreaterThan(model.timeBonus, 0)
        XCTAssertEqual(best.score, model.score, "the score shown on the win screen, bonus included")
        XCTAssertEqual(best.seconds, Self.winningSeconds)
        XCTAssertEqual(best.moves, model.moveCount)
        XCTAssertEqual(best.dealNumber, model.dealNumber)
        XCTAssertTrue(bestScores[.one].isEmpty)
    }

    func testAnUntimedWinIsRankedWithoutATime() throws {
        settings.timed = false
        let game = try Game.oneMoveFromWinning(scoringMode: .standard)
        let model = makeModel(resuming: SavedGame(game: game, elapsedSeconds: Self.winningSeconds))

        try playLastMove(model)

        let best = try XCTUnwrap(bestScores[.one].first)
        XCTAssertNil(best.seconds)
        XCTAssertEqual(best.score, model.score)
    }

    func testVegasAndUnscoredWinsAreNotRanked() throws {
        for scoringMode in [ScoringMode.vegas, .none] {
            let game = try Game.oneMoveFromWinning(scoringMode: scoringMode)
            let model = makeModel(resuming: SavedGame(game: game, elapsedSeconds: Self.winningSeconds))
            try playLastMove(model)
            XCTAssertTrue(model.isWon)
        }
        XCTAssertEqual(recorded.overall.won, 2)
        XCTAssertNil(bestScoresStore.saved)
    }
}
