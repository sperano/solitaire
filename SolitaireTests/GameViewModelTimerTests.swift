import SolitaireKit
import XCTest
@testable import Solitaire

/// The game clock on an injected `TestClock`: when it runs, pauses, resumes and is saved.
@MainActor
final class GameViewModelTimerTests: XCTestCase {
    private static let fixedSeed: UInt64 = 99
    private static let savedElapsed = 65
    private static let longGameSeconds = 100

    private var suiteName = ""
    private var defaults: UserDefaults!
    private var settings: GameSettings!
    private var store: InMemoryGameStore!
    private var statisticsStore: InMemoryStatisticsStore!
    private var clock: TestClock!

    override func setUp() async throws {
        suiteName = "quebec.spe.SolitaireTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        settings = GameSettings(defaults: defaults)
        store = InMemoryGameStore()
        statisticsStore = InMemoryStatisticsStore()
        clock = TestClock()
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private func makeModel() -> GameViewModel {
        GameViewModel(
            store: store, settings: settings, statistics: StatisticsModel(store: statisticsStore),
            fixedSeed: Self.fixedSeed, clock: clock
        )
    }

    private func makeModel(resuming saved: SavedGame) -> GameViewModel {
        store = InMemoryGameStore(saved: saved)
        return makeModel()
    }

    /// A model whose clock is running: one move made, and the tick task under way.
    private func makeStartedModel() async -> GameViewModel {
        let model = makeModel()
        model.draw()
        await clock.waitForSleeper()
        return model
    }

    // MARK: Running

    func testTheClockWaitsForTheFirstMove() async {
        let model = makeModel()
        await clock.advance(by: .seconds(5))
        XCTAssertEqual(model.elapsedSeconds, 0)
        XCTAssertEqual(clock.sleeperCount, 0, "no tick is scheduled")
    }

    func testTheClockCountsWholeSecondsFromTheFirstMoveAndSavesEachTick() async {
        let model = await makeStartedModel()
        XCTAssertEqual(clock.sleeperCount, 1, "ticking")

        await clock.advance(by: .seconds(3))

        XCTAssertEqual(model.elapsedSeconds, 3)
        XCTAssertEqual(store.saved?.elapsedSeconds, 3)
        XCTAssertEqual(model.formattedTime, "0:03")
    }

    func testTheClockStopsAtTheWin() async throws {
        let game = try Game.oneMoveFromWinning()
        let model = makeModel(resuming: SavedGame(game: game, elapsedSeconds: Self.savedElapsed))
        let column = try XCTUnwrap(PileID.allTableau.first { !model.state.pile($0).isEmpty })

        model.tapCard(in: column, index: model.state.pile(column).count - 1)
        XCTAssertTrue(model.isWon)
        await clock.advance(by: .seconds(10))

        XCTAssertEqual(model.elapsedSeconds, Self.savedElapsed, "the winning move stopped the clock at once")
        XCTAssertEqual(clock.sleeperCount, 0)
        XCTAssertEqual(statisticsStore.saved?[.one].bestTimeSeconds, Self.savedElapsed)
    }

    func testANewGameStartsFromZero() async {
        let model = await makeStartedModel()
        await clock.advance(by: .seconds(4))
        model.newGame()
        XCTAssertEqual(model.elapsedSeconds, 0)
        XCTAssertEqual(clock.sleeperCount, 0)
        model.draw()
        await clock.waitForSleeper()
        await clock.advance(by: .seconds(1))
        XCTAssertEqual(model.elapsedSeconds, 1)
        XCTAssertEqual(store.saved?.elapsedSeconds, 1, "the tick saved it")
    }

    // MARK: Pausing

    func testTheClockPausesInTheBackgroundAndSavesTheTimeSoFar() async {
        let model = await makeStartedModel()
        await clock.advance(by: .seconds(2))

        model.setAppActive(false)
        XCTAssertEqual(clock.sleeperCount, 0, "no tick while paused")
        XCTAssertEqual(store.saved?.elapsedSeconds, 2)
        await clock.advance(by: .seconds(60))
        XCTAssertEqual(model.elapsedSeconds, 2)

        model.setAppActive(true)
        await clock.advance(by: .seconds(3))
        XCTAssertEqual(model.elapsedSeconds, 5)
    }

    func testTheClockPausesWhileSettingsAreOpen() async {
        let model = await makeStartedModel()
        await clock.advance(by: .seconds(1))

        model.isShowingSettings = true
        await clock.advance(by: .seconds(30))
        XCTAssertEqual(model.elapsedSeconds, 1)

        model.isShowingSettings = false
        await clock.advance(by: .seconds(1))
        XCTAssertEqual(model.elapsedSeconds, 2)
    }

    func testPausesShorterThanASecondAddUp() async {
        let model = await makeStartedModel()
        for _ in 0 ..< 4 {
            await clock.advance(by: .milliseconds(300))
            model.setAppActive(false)
            await clock.advance(by: .seconds(5))
            model.setAppActive(true)
        }
        XCTAssertEqual(model.elapsedSeconds, 1, "4 × 0.3 s of play")
    }

    func testTheClockDoesNotRunWhileADealIsSearchedFor() async {
        settings.winnableDealsOnly = true
        let model = GameViewModel(
            store: store, settings: settings, statistics: StatisticsModel(store: statisticsStore), fixedSeed: nil, clock: clock
        )
        XCTAssertTrue(model.isDealing)
        model.setAppActive(true)
        XCTAssertEqual(clock.sleeperCount, 0)
        model.playDeal(number: Self.fixedSeed)
    }

    // MARK: Relaunch

    func testARelaunchContinuesFromTheSavedTime() async {
        let model = makeModel(resuming: SavedGame(game: Game(seed: Self.fixedSeed, drawMode: .one), elapsedSeconds: Self.savedElapsed))
        XCTAssertEqual(model.elapsedSeconds, Self.savedElapsed)
        XCTAssertEqual(clock.sleeperCount, 0, "no move yet, the clock waits")

        model.draw()
        await clock.advance(by: .seconds(1))
        XCTAssertEqual(model.elapsedSeconds, Self.savedElapsed + 1)
    }

    // MARK: Untimed

    func testUntimedGamesHaveNoClockNoBonusAndNoBestTime() async throws {
        settings.timed = false
        var game = Game.completable(scoringMode: .standard)
        let model = makeModel(resuming: SavedGame(game: game, elapsedSeconds: Self.longGameSeconds))
        model.draw()
        XCTAssertEqual(clock.sleeperCount, 0)
        await clock.advance(by: .seconds(5))
        XCTAssertEqual(model.elapsedSeconds, Self.longGameSeconds, "the saved time is kept but does not grow")

        while let move = game.nextAutoCompleteMove() { try game.perform(move) }
        let won = makeModel(resuming: SavedGame(game: game, elapsedSeconds: Self.longGameSeconds))
        XCTAssertEqual(won.timeBonus, 0)
        XCTAssertEqual(won.score, game.score)
    }

    func testAnUntimedWinRecordsMovesButNoTime() throws {
        settings.timed = false
        let model = makeModel(resuming: SavedGame(game: try Game.oneMoveFromWinning(), elapsedSeconds: Self.savedElapsed))
        let column = try XCTUnwrap(PileID.allTableau.first { !model.state.pile($0).isEmpty })

        model.tapCard(in: column, index: model.state.pile(column).count - 1)

        XCTAssertTrue(model.isWon)
        XCTAssertEqual(statisticsStore.saved?[.one].won, 1)
        XCTAssertNil(statisticsStore.saved?[.one].bestTimeSeconds)
        XCTAssertEqual(statisticsStore.saved?[.one].fewestMoves, model.moveCount)
    }

    func testTurningTheTimerOffAndOnInSettingsTakesEffectWhenTheyClose() async {
        let model = await makeStartedModel()
        model.isShowingSettings = true
        settings.timed = false
        model.isShowingSettings = false
        model.settingsDismissed()
        await clock.advance(by: .seconds(5))
        XCTAssertEqual(model.elapsedSeconds, 0)

        model.isShowingSettings = true
        settings.timed = true
        model.isShowingSettings = false
        model.settingsDismissed()
        await clock.advance(by: .seconds(5))
        XCTAssertEqual(model.elapsedSeconds, 5)
    }
}
