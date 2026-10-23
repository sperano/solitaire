import SolitaireKit
import XCTest
@testable import Solitaire

@MainActor
final class GameViewModelTests: XCTestCase {
    private static let fixedSeed: UInt64 = 99
    private static let savedSeed: UInt64 = 5
    private static let savedElapsed = 65
    private static let seedSearchRange: ClosedRange<UInt64> = 0 ... 200
    private static let carriedBalance = 100
    private static let longGameSeconds = 100
    private static let autoCompleteWaitLimit = Duration.seconds(10)
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

    private func makeModel(fixedSeed: UInt64? = GameViewModelTests.fixedSeed) -> GameViewModel {
        GameViewModel(
            store: store, settings: settings, statistics: StatisticsModel(store: InMemoryStatisticsStore()),
            fixedSeed: fixedSeed
        )
    }

    private func makeModel(resuming saved: SavedGame) -> GameViewModel {
        store = InMemoryGameStore(saved: saved)
        return makeModel()
    }

    /// First seed in range and tableau column whose top card has an auto-move destination (or none).
    private func findTableauTap(hasDestination: Bool) throws -> (seed: UInt64, pile: PileID, destination: PileID?) {
        for seed in Self.seedSearchRange {
            let game = Game(seed: seed, drawMode: .one)
            for pile in PileID.allTableau {
                let destination = game.autoMoveDestination(count: 1, from: pile)
                if (destination != nil) == hasDestination { return (seed, pile, destination) }
            }
        }
        throw XCTSkip("no suitable seed found")
    }

    // MARK: Init

    func testNewModelDealsFixedSeedWithSettingsDrawMode() {
        settings.drawMode = .three
        let model = makeModel()

        XCTAssertEqual(model.state.seed, Self.fixedSeed)
        XCTAssertEqual(model.state.drawMode, .three)
        XCTAssertEqual(model.moveCount, 0)
        XCTAssertEqual(model.elapsedSeconds, 0)
    }

    func testModelResumesSavedGameInsteadOfDealing() throws {
        var game = Game(seed: Self.savedSeed, drawMode: .one)
        try game.perform(.draw)
        let model = makeModel(resuming: SavedGame(game: game, elapsedSeconds: Self.savedElapsed))

        XCTAssertEqual(model.game, game)
        XCTAssertEqual(model.state.seed, Self.savedSeed)
        XCTAssertEqual(model.elapsedSeconds, Self.savedElapsed)
    }

    // MARK: Draw and undo

    func testCanUndoIsFalseAtStart() {
        XCTAssertFalse(makeModel().canUndo)
    }

    func testDrawIncrementsMoveCountAndPersists() {
        let model = makeModel()
        model.draw()

        XCTAssertEqual(model.moveCount, 1)
        XCTAssertTrue(model.canUndo)
        XCTAssertEqual(store.saved?.game, model.game)
    }

    func testUndoRestoresPreviousStateAndPersists() {
        let model = makeModel()
        let initial = model.state
        model.draw()

        model.undo()

        XCTAssertEqual(model.state, initial)
        XCTAssertFalse(model.canUndo)
        XCTAssertEqual(store.saved?.game.state, initial)
    }

    func testUndoWithNothingToUndoDoesNotChangeState() {
        let model = makeModel()
        let initial = model.state
        model.undo()
        XCTAssertEqual(model.state, initial)
    }

    // MARK: New game

    func testNewGameResetsAndUsesCurrentDrawModeAndPersists() {
        let model = makeModel()
        model.draw()
        settings.drawMode = .three

        model.newGame()

        XCTAssertEqual(model.moveCount, 0)
        XCTAssertEqual(model.elapsedSeconds, 0)
        XCTAssertEqual(model.state.drawMode, .three)
        XCTAssertFalse(model.canUndo)
        XCTAssertEqual(store.saved?.game, model.game)
        XCTAssertEqual(store.saved?.elapsedSeconds, 0)
    }

    func testRequestNewGameOnAnUntouchedDealStartsOverAtOnce() {
        let model = makeModel()
        model.requestNewGame()
        XCTAssertFalse(model.isConfirmingNewGame)
        XCTAssertEqual(model.moveCount, 0)
    }

    func testRequestNewGameAfterAMoveAsksFirst() {
        let model = makeModel()
        model.draw()
        model.requestNewGame()
        XCTAssertTrue(model.isConfirmingNewGame)
        XCTAssertEqual(model.moveCount, 1, "the game waits for the answer")
    }

    func testRequestNewGameOnAWonGameStartsOverAtOnce() async {
        let model = makeModel(resuming: SavedGame(game: Game.completable(), elapsedSeconds: 0))
        model.autoComplete()
        await waitForAutoComplete(model)
        XCTAssertTrue(model.isWon)
        model.requestNewGame()
        XCTAssertFalse(model.isConfirmingNewGame)
        XCTAssertFalse(model.isWon)
    }

    func testNewGameClearsDrag() {
        let model = makeModel()
        model.drag = DragInfo(source: .waste, count: 1, translation: .zero)
        model.newGame()
        XCTAssertNil(model.drag)
    }

    // MARK: Tap

    func testTapCardPerformsLegalAutoMove() throws {
        let found = try findTableauTap(hasDestination: true)
        let model = makeModel(fixedSeed: found.seed)
        let top = model.state.pile(found.pile).count - 1

        model.tapCard(in: found.pile, index: top)

        XCTAssertEqual(model.moveCount, 1)
        XCTAssertEqual(store.saved?.game, model.game)
    }

    func testTapCardIgnoresIllegalMove() throws {
        let found = try findTableauTap(hasDestination: false)
        let model = makeModel(fixedSeed: found.seed)
        let top = model.state.pile(found.pile).count - 1

        model.tapCard(in: found.pile, index: top)

        XCTAssertEqual(model.moveCount, 0)
        XCTAssertNil(store.saved)
    }

    func testTapCardMoveCountChangesIffAutoMoveDestinationExists() {
        for seed in Self.seedSearchRange.prefix(20) {
            for pile in PileID.allTableau {
                store = InMemoryGameStore()
                let model = makeModel(fixedSeed: seed)
                let top = model.state.pile(pile).count - 1
                let expected = model.game.autoMoveDestination(count: 1, from: pile) != nil

                model.tapCard(in: pile, index: top)

                XCTAssertEqual(model.moveCount == 1, expected, "seed \(seed) \(pile)")
            }
        }
    }

    // MARK: Drop

    func testDropWithoutDragReturnsFalse() {
        let model = makeModel()
        XCTAssertFalse(model.drop(on: .tableau(0)))
        XCTAssertEqual(model.moveCount, 0)
    }

    func testDropPerformsLegalMoveAndClearsDrag() throws {
        let found = try findTableauTap(hasDestination: true)
        let destination = try XCTUnwrap(found.destination)
        let model = makeModel(fixedSeed: found.seed)
        model.drag = DragInfo(source: found.pile, count: 1, translation: .zero)

        XCTAssertTrue(model.drop(on: destination))

        XCTAssertEqual(model.moveCount, 1)
        XCTAssertNil(model.drag)
    }

    func testDropIllegalReturnsFalseAndClearsDrag() throws {
        let found = try findTableauTap(hasDestination: false)
        let model = makeModel(fixedSeed: found.seed)
        model.drag = DragInfo(source: found.pile, count: 1, translation: .zero)

        XCTAssertFalse(model.drop(on: .stock))

        XCTAssertEqual(model.moveCount, 0)
        XCTAssertNil(model.drag)
    }

    func testDropOnNoDestinationReturnsFalseAndClearsDrag() {
        let model = makeModel()
        model.drag = DragInfo(source: .tableau(0), count: 1, translation: .zero)
        XCTAssertFalse(model.drop(on: nil))
        XCTAssertNil(model.drag)
    }

    // MARK: Time

    func testFormattedTime() {
        XCTAssertEqual(makeModel().formattedTime, "0:00")
        let game = Game(seed: Self.savedSeed, drawMode: .one)
        let model = makeModel(resuming: SavedGame(game: game, elapsedSeconds: Self.savedElapsed))
        XCTAssertEqual(model.formattedTime, "1:05")
    }

    // MARK: Auto-complete

    func testCanAutoCompleteFalseOnFreshDeal() {
        XCTAssertFalse(makeModel().canAutoComplete)
    }

    func testAutoCompleteDoesNothingWhenNotCompletable() {
        let model = makeModel()
        model.autoComplete()
        XCTAssertFalse(model.isAutoCompleting)
        XCTAssertEqual(model.moveCount, 0)
    }

    func testCanAutoCompleteOnCompletablePosition() throws {
        let game = Game.completable()
        let model = makeModel(resuming: SavedGame(game: game, elapsedSeconds: 0))
        XCTAssertTrue(model.canAutoComplete)
        XCTAssertFalse(model.isWon)
    }

    func testAutoCompleteFinishesTheGame() async throws {
        let game = Game.completable()
        let model = makeModel(resuming: SavedGame(game: game, elapsedSeconds: 0))

        model.autoComplete()
        XCTAssertTrue(model.isAutoCompleting)
        XCTAssertFalse(model.canUndo)

        await waitForAutoComplete(model)
        XCTAssertTrue(model.isWon)
        XCTAssertEqual(model.moveCount, Game.completableRemainingCardCount)
        XCTAssertFalse(model.isAutoCompleting)
    }

    func testBoardIgnoresInputWhileAutoCompleting() throws {
        let game = Game.completable()
        let model = makeModel(resuming: SavedGame(game: game, elapsedSeconds: 0))
        let column = try XCTUnwrap(PileID.allTableau.first { !model.state.pile($0).isEmpty })
        let top = model.state.pile(column).count - 1

        model.autoComplete()
        XCTAssertFalse(model.acceptsInput)
        model.tapCard(in: column, index: top)
        model.drag = DragInfo(source: column, count: 1, translation: .zero)
        XCTAssertFalse(model.drop(on: .foundation(0)))
        XCTAssertEqual(model.moveCount, 0, "no move may slip in before auto-complete runs")
    }

    func testAutoFinishStartsOnceTheLastBlockingCardIsPlayed() async {
        settings.autoFinish = true
        let model = makeModel(resuming: SavedGame(game: Game.oneMoveFromCompletable(), elapsedSeconds: 0))
        XCTAssertFalse(model.isAutoCompleting)

        model.tapCard(in: .waste, index: 0)
        XCTAssertTrue(model.isAutoCompleting)
        await waitForAutoComplete(model)
        XCTAssertTrue(model.isWon)
    }

    func testWithoutAutoFinishTheFinishButtonWaits() {
        let model = makeModel(resuming: SavedGame(game: Game.oneMoveFromCompletable(), elapsedSeconds: 0))
        model.tapCard(in: .waste, index: 0)
        XCTAssertFalse(model.isAutoCompleting)
        XCTAssertTrue(model.canAutoComplete)
    }

    func testAutoFinishStartsWhenACompletableGameIsResumed() async {
        settings.autoFinish = true
        let model = makeModel(resuming: SavedGame(game: Game.completable(), elapsedSeconds: 0))
        XCTAssertTrue(model.isAutoCompleting)
        await waitForAutoComplete(model)
        XCTAssertTrue(model.isWon)
    }

    func testUndoingAnAutoFinishedWinDoesNotFinishAgain() async {
        settings.autoFinish = true
        let model = makeModel(resuming: SavedGame(game: Game.completable(), elapsedSeconds: 0))
        await waitForAutoComplete(model)

        model.undo()
        XCTAssertFalse(model.isWon)
        XCTAssertFalse(model.isAutoCompleting)
        XCTAssertTrue(model.canAutoComplete)
    }

    func testTurningAutoFinishOnWhileFinishIsOfferedTakesEffectWhenSettingsClose() async {
        let model = makeModel(resuming: SavedGame(game: Game.completable(), elapsedSeconds: 0))
        model.settingsDismissed()
        XCTAssertFalse(model.isAutoCompleting, "the setting is still off")

        settings.autoFinish = true
        model.settingsDismissed()
        XCTAssertTrue(model.isAutoCompleting)
        await waitForAutoComplete(model)
        XCTAssertTrue(model.isWon)
    }

    private func waitForAutoComplete(_ model: GameViewModel) async {
        let deadline = ContinuousClock.now + Self.autoCompleteWaitLimit
        while model.isAutoCompleting, ContinuousClock.now < deadline {
            try? await Task.sleep(for: Self.pollInterval)
        }
    }

    func testAcceptsInputDuringNormalPlay() {
        XCTAssertTrue(makeModel().acceptsInput)
    }

    // MARK: Scoring

    func testNewGameUsesSettingsScoringMode() {
        XCTAssertEqual(makeModel().scoringMode, GameSettings.defaultScoringMode)
        settings.scoringMode = .vegas
        let model = makeModel()
        XCTAssertEqual(model.scoringMode, .vegas)
        XCTAssertEqual(model.score, -Scoring.vegasBuyIn)
    }

    func testScoringModeChangeAppliesToTheNextGame() {
        let model = makeModel()
        settings.scoringMode = .none
        XCTAssertEqual(model.scoringMode, .standard)
        model.newGame()
        XCTAssertEqual(model.scoringMode, ScoringMode.none)
    }

    func testVegasBalanceCarriesIntoTheNextGameWhenEnabled() {
        settings.scoringMode = .vegas
        settings.carryVegasBalance = true
        let model = makeModel()

        model.newGame()

        XCTAssertEqual(settings.vegasBalance, -Scoring.vegasBuyIn, "the abandoned game's balance is kept")
        XCTAssertEqual(model.score, -2 * Scoring.vegasBuyIn)
    }

    func testEveryVegasGameStartsFromZeroWithoutCarry() {
        settings.scoringMode = .vegas
        let model = makeModel()
        model.newGame()
        XCTAssertEqual(model.score, -Scoring.vegasBuyIn)
        XCTAssertEqual(settings.vegasBalance, 0)
    }

    func testFinishingANonVegasGameLeavesTheCarriedBalanceAlone() {
        settings.carryVegasBalance = true
        settings.vegasBalance = Self.carriedBalance
        let model = makeModel()
        settings.scoringMode = .vegas

        model.newGame()

        XCTAssertEqual(settings.vegasBalance, Self.carriedBalance)
        XCTAssertEqual(model.score, Self.carriedBalance - Scoring.vegasBuyIn)
    }

    func testFormattedScoreByMode() {
        settings.scoringMode = .none
        XCTAssertNil(makeModel().formattedScore)
        settings.scoringMode = .standard
        XCTAssertEqual(makeModel().formattedScore, "0")
        settings.scoringMode = .vegas
        XCTAssertEqual(makeModel().formattedScore, "-$\(Scoring.vegasBuyIn)")
        settings.carryVegasBalance = true
        settings.vegasBalance = Self.carriedBalance
        XCTAssertEqual(makeModel().formattedScore, "$\(Self.carriedBalance - Scoring.vegasBuyIn)")
    }

    func testWonStandardGameAddsTheTimeBonus() throws {
        var game = Game.completable(scoringMode: .standard)
        while let move = game.nextAutoCompleteMove() { try game.perform(move) }
        XCTAssertTrue(game.isWon)
        let model = makeModel(resuming: SavedGame(game: game, elapsedSeconds: Self.longGameSeconds))

        let bonus = Scoring.timeBonusNumerator / Self.longGameSeconds
        XCTAssertEqual(model.timeBonus, bonus)
        XCTAssertEqual(model.score, game.score + bonus)
    }

    func testNoTimeBonusBeforeTheWin() throws {
        let game = Game.completable(scoringMode: .standard)
        let model = makeModel(resuming: SavedGame(game: game, elapsedSeconds: Self.longGameSeconds))
        XCTAssertEqual(model.timeBonus, 0)
        XCTAssertEqual(model.score, game.score)
    }

    func testStockStopsOnceVegasPassesAreUsedUp() {
        settings.scoringMode = .vegas
        let model = makeModel()
        while !model.state.stock.isEmpty { model.draw() }
        let drawn = model.moveCount

        XCTAssertFalse(model.canDraw)
        model.draw()
        XCTAssertEqual(model.moveCount, drawn)
    }
}
