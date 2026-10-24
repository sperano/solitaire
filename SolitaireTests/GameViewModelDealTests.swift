import SolitaireKit
import XCTest
@testable import Solitaire

/// Deal numbers, replaying a deal and the winnable-deals-only search.
@MainActor
final class GameViewModelDealTests: XCTestCase {
    private static let fixedSeed: UInt64 = 99
    private static let otherSeed: UInt64 = 5
    private static let dealingWaitLimit = Duration.seconds(60)
    private static let pollInterval = Duration.milliseconds(10)

    private var suiteName = ""
    private var defaults: UserDefaults!
    private var settings: GameSettings!
    private var store: InMemoryGameStore!

    override func setUp() async throws {
        suiteName = "quebec.spe.SolitaireTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        settings = GameSettings(defaults: defaults)
        store = InMemoryGameStore()
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private func makeModel(fixedSeed: UInt64? = GameViewModelDealTests.fixedSeed) -> GameViewModel {
        GameViewModel(
            store: store, settings: settings, statistics: StatisticsModel(store: InMemoryStatisticsStore()),
            fixedSeed: fixedSeed
        )
    }

    private func makeModel(resuming saved: SavedGame) -> GameViewModel {
        store = InMemoryGameStore(saved: saved)
        return makeModel()
    }

    // MARK: Deal numbers

    func testDealNumberIsTheSeedAndNewGamesStayInRange() {
        let model = makeModel(fixedSeed: nil)
        XCTAssertTrue(GameState.dealNumberRange.contains(model.dealNumber))
        model.newGame()
        XCTAssertTrue(GameState.dealNumberRange.contains(model.dealNumber))
    }

    func testReplayDealKeepsTheNumberAndStartsOver() {
        let model = makeModel(fixedSeed: nil)
        let number = model.dealNumber
        model.draw()

        model.replayDeal()

        XCTAssertEqual(model.dealNumber, number)
        XCTAssertEqual(model.moveCount, 0)
        XCTAssertFalse(model.canUndo)
        XCTAssertEqual(store.saved?.game, model.game)
    }

    func testPlayDealDealsThatNumberInTheCurrentSettingsAndCountsTheLoss() {
        let statistics = StatisticsModel(store: InMemoryStatisticsStore())
        let model = GameViewModel(store: store, settings: settings, statistics: statistics, fixedSeed: nil)
        model.draw()
        settings.drawMode = .three

        model.playDeal(number: Self.otherSeed)

        XCTAssertEqual(model.dealNumber, Self.otherSeed)
        XCTAssertEqual(model.state.drawMode, .three)
        XCTAssertEqual(
            model.state,
            GameState.deal(seed: Self.otherSeed, drawMode: .three, scoringMode: settings.scoringMode)
        )
        XCTAssertEqual(statistics.statistics.overall.played, 1)
        XCTAssertEqual(statistics.statistics.overall.won, 0)
    }

    func testPlayDealIgnoresWinnableDealsOnly() {
        settings.winnableDealsOnly = true
        let model = makeModel(fixedSeed: nil)
        model.playDeal(number: DealSearchTests.rejectedSeed)
        XCTAssertFalse(model.isDealing)
        XCTAssertEqual(model.dealNumber, DealSearchTests.rejectedSeed)
    }

    // MARK: Winnable deals

    func testNewGameWithWinnableDealsOnlySearchesOffTheBoardThenDealsAWinnableGame() async {
        settings.winnableDealsOnly = true
        let model = makeModel(fixedSeed: nil)
        await waitForDealing(model)
        model.draw()
        let previous = model.game

        model.newGame()

        XCTAssertTrue(model.isDealing)
        XCTAssertEqual(model.game, previous, "the board keeps the old game while searching")
        XCTAssertFalse(model.acceptsInput)
        XCTAssertFalse(model.canUndo)
        await waitForDealing(model)
        XCTAssertFalse(model.isDealing)
        XCTAssertEqual(model.moveCount, 0)
        XCTAssertTrue(model.acceptsInput)
        XCTAssertEqual(store.saved?.game, model.game)
        if case .solved = Solver().solve(model.state).outcome {} else { XCTFail("the dealt game must be winnable") }
    }

    func testAFixedSeedIsDealtWithoutSearching() {
        settings.winnableDealsOnly = true
        let model = makeModel()
        model.newGame()
        XCTAssertFalse(model.isDealing)
        XCTAssertEqual(model.dealNumber, Self.fixedSeed)
    }

    func testLaunchWithoutASaveSearchesAndKeepsAWinnableFirstDeal() async {
        settings.winnableDealsOnly = true
        let model = makeModel(fixedSeed: nil)

        XCTAssertTrue(model.isDealing)
        XCTAssertNil(store.saved, "nothing is saved until the deal is known to be winnable")
        await waitForDealing(model)
        XCTAssertEqual(store.saved?.game, model.game)
        if case .solved = Solver().solve(model.state).outcome {} else { XCTFail("the dealt game must be winnable") }
    }

    func testANewGameDuringASearchCancelsItAndStartsAnother() async {
        settings.winnableDealsOnly = true
        let model = makeModel(fixedSeed: nil)
        XCTAssertTrue(model.isDealing)

        model.playDeal(number: Self.otherSeed)

        XCTAssertFalse(model.isDealing)
        XCTAssertEqual(model.dealNumber, Self.otherSeed)
        // The cancelled search must not install its deal later.
        try? await Task.sleep(for: Self.pollInterval)
        XCTAssertEqual(model.dealNumber, Self.otherSeed)
    }

    func testASavedGameIsResumedWithoutSearching() {
        settings.winnableDealsOnly = true
        let game = Game(seed: Self.otherSeed, drawMode: .one)
        let model = makeModel(resuming: SavedGame(game: game, elapsedSeconds: 0))
        XCTAssertFalse(model.isDealing)
        XCTAssertEqual(model.game, game)
    }

    private func waitForDealing(_ model: GameViewModel) async {
        let deadline = ContinuousClock.now + Self.dealingWaitLimit
        while model.isDealing, ContinuousClock.now < deadline {
            try? await Task.sleep(for: Self.pollInterval)
        }
    }
}
