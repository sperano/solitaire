import SolitaireKit
import XCTest
@testable import Solitaire

@MainActor
private final class HapticsSpy: HapticPlayer {
    private(set) var played: [HapticEvent] = []
    func play(_ event: HapticEvent) { played.append(event) }
}

/// Haptics and the drop the board animates from. Seed 42's tableau tops: 2♣ 8♣ Q♣ 5♥ 6♠ 5♣ A♥.
@MainActor
final class GameViewModelFeedbackTests: XCTestCase {
    private static let seed: UInt64 = 42
    private static let aceColumn = PileID.tableau(6)
    private static let waitLimit = Duration.seconds(10)
    private static let pollInterval = Duration.milliseconds(10)

    private var suiteName = ""
    private var defaults: UserDefaults!
    private var settings: GameSettings!
    private var spy: HapticsSpy!

    override func setUp() async throws {
        suiteName = "quebec.spe.SolitaireTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        settings = GameSettings(defaults: defaults)
        spy = HapticsSpy()
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private func makeModel(resuming game: Game? = nil) -> GameViewModel {
        GameViewModel(
            store: InMemoryGameStore(saved: game.map { SavedGame(game: $0, elapsedSeconds: 0) }),
            settings: settings, statistics: StatisticsModel(store: InMemoryStatisticsStore()),
            haptics: spy, fixedSeed: Self.seed
        )
    }

    private func top(_ pile: PileID, _ model: GameViewModel) -> Int { model.state.pile(pile).count - 1 }

    // MARK: Haptics

    func testAMoveIsFelt() {
        let model = makeModel()
        model.tapCard(in: Self.aceColumn, index: top(Self.aceColumn, model))
        model.draw()
        XCTAssertEqual(spy.played, [.move, .move])
    }

    func testATapWithNowhereToGoIsRefused() {
        let model = makeModel()
        model.tapCard(in: .tableau(0), index: 0)
        XCTAssertEqual(spy.played, [.invalidMove])
        XCTAssertEqual(model.moveCount, 0)
    }

    func testAnIllegalDropIsRefused() {
        let model = makeModel()
        model.drag = DragInfo(source: .tableau(0), count: 1, translation: .zero)
        XCTAssertFalse(model.drop(on: .foundation(0)))
        XCTAssertEqual(spy.played, [.invalidMove])
    }

    func testLettingGoAwayFromAnyPileIsNotFelt() {
        let model = makeModel()
        model.drag = DragInfo(source: .tableau(0), count: 1, translation: .zero)
        XCTAssertFalse(model.drop(on: nil))
        XCTAssertEqual(spy.played, [])
    }

    func testDrawingFromAnEmptyBoardIsRefused() {
        let model = makeModel(resuming: Game(state: FixturePosition.deadlocked.state()))
        model.draw()
        XCTAssertEqual(spy.played, [.invalidMove])
    }

    func testTheWinningMoveIsFeltAsTheWin() throws {
        let model = makeModel(resuming: try Game.oneMoveFromWinning())
        let column = try XCTUnwrap(PileID.allTableau.first { !model.state.pile($0).isEmpty })
        model.tapCard(in: column, index: 0)
        XCTAssertTrue(model.isWon)
        XCTAssertEqual(spy.played, [.win])
    }

    func testAutoCompleteIsFeltOnlyWhenItWins() async {
        let model = makeModel(resuming: Game.completable())
        model.autoComplete()
        let deadline = ContinuousClock.now + Self.waitLimit
        while model.isAutoCompleting, ContinuousClock.now < deadline {
            try? await Task.sleep(for: Self.pollInterval)
        }
        XCTAssertTrue(model.isWon)
        XCTAssertEqual(spy.played, [.win])
    }

    func testNothingIsFeltWithHapticsOff() {
        settings.haptics = false
        let model = makeModel()
        model.tapCard(in: Self.aceColumn, index: top(Self.aceColumn, model))
        model.tapCard(in: .tableau(0), index: 0)
        XCTAssertEqual(spy.played, [])
    }

    // MARK: Last drop

    func testASuccessfulDropIsRemembered() {
        let model = makeModel()
        let drag = DragInfo(source: Self.aceColumn, count: 1, translation: CGSize(width: 10, height: -200))
        model.drag = drag
        XCTAssertTrue(model.drop(on: .foundation(0)))
        XCTAssertEqual(model.lastDrop, drag)
    }

    func testAFailedDropIsNotRemembered() {
        let model = makeModel()
        model.drag = DragInfo(source: .tableau(0), count: 1, translation: .zero)
        model.drop(on: .foundation(0))
        XCTAssertNil(model.lastDrop)
    }

    func testTheNextMoveUndoOrDealForgetsTheDrop() {
        let model = makeModel()
        func drop() {
            model.drag = DragInfo(source: Self.aceColumn, count: 1, translation: .zero)
            model.drop(on: .foundation(0))
            XCTAssertNotNil(model.lastDrop)
        }
        drop()
        model.draw()
        XCTAssertNil(model.lastDrop, "a tap-driven move")
        model.undo()
        model.undo()
        drop()
        model.undo()
        XCTAssertNil(model.lastDrop, "undo")
        drop()
        model.newGame()
        XCTAssertNil(model.lastDrop, "new game")
    }

    // MARK: canDrop

    func testCanDropMatchesTheRules() {
        let model = makeModel()
        XCTAssertFalse(model.canDrop(on: .foundation(0)), "nothing is being dragged")
        model.drag = DragInfo(source: Self.aceColumn, count: 1, translation: .zero)
        XCTAssertTrue(model.canDrop(on: .foundation(0)))
        XCTAssertFalse(model.canDrop(on: .tableau(3)))
        XCTAssertFalse(model.canDrop(on: nil))
        XCTAssertEqual(model.moveCount, 0, "asking never moves")
    }
}
