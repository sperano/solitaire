import SolitaireKit
import XCTest
@testable import Solitaire

@MainActor
final class GameViewModelAccessibilityTests: XCTestCase {
    /// Seed 42's tableau tops: 2♣ 8♣ Q♣ 5♥ 6♠ 5♣ A♥.
    private static let seed: UInt64 = 42
    private static let fiveOfHeartsColumn = PileID.tableau(3)
    private static let sixOfSpadesColumn = PileID.tableau(4)
    private static let aceOfHeartsColumn = PileID.tableau(6)

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

    private func makeModel(resuming game: Game? = nil) -> GameViewModel {
        GameViewModel(
            store: InMemoryGameStore(saved: game.map { SavedGame(game: $0, elapsedSeconds: 0) }),
            settings: GameSettings(defaults: defaults),
            statistics: StatisticsModel(store: InMemoryStatisticsStore()),
            fixedSeed: Self.seed
        )
    }

    private func top(_ pile: PileID, _ model: GameViewModel) -> Int { model.state.pile(pile).count - 1 }

    // MARK: destinations

    func testAnAceCanGoToAFoundationOrOnTheTwoOfClubs() {
        let model = makeModel()
        XCTAssertEqual(
            model.destinations(forCardAt: top(Self.aceOfHeartsColumn, model), in: Self.aceOfHeartsColumn),
            [.foundation(0), .tableau(0)], "a red ace may also go on the black two"
        )
    }

    func testARedFiveCanGoOnTheBlackSix() {
        let model = makeModel()
        XCTAssertEqual(
            model.destinations(forCardAt: top(Self.fiveOfHeartsColumn, model), in: Self.fiveOfHeartsColumn),
            [Self.sixOfSpadesColumn]
        )
    }

    func testAStuckCardHasNoDestination() {
        let model = makeModel()
        XCTAssertEqual(model.destinations(forCardAt: 0, in: .tableau(0)), [])
    }

    func testFaceDownCardsHaveNoDestination() {
        let model = makeModel()
        XCTAssertEqual(model.destinations(forCardAt: 0, in: Self.aceOfHeartsColumn), [])
    }

    func testOnlyTheTopWasteCardMoves() {
        let model = makeModel(resuming: Game(state: FixturePosition.oneMoveFromCompletable.state()))
        // The seven of hearts goes to its foundation or onto the eight of spades.
        XCTAssertEqual(model.destinations(forCardAt: 0, in: .waste), [.foundation(2), .tableau(1)])
        XCTAssertEqual(model.destinations(forCardAt: 1, in: .waste), [], "past the top of the pile")
    }

    func testAFoundationCardIsOfferedColumnsButNeverAnotherFoundation() {
        let model = makeModel(resuming: Game(state: FixturePosition.oneMoveFromCompletable.state()))
        // The six of hearts fits on the seven of spades that tops the first column.
        let hearts = PileID.foundation(2)
        XCTAssertEqual(model.destinations(forCardAt: top(hearts, model), in: hearts), [.tableau(0)])
    }

    func testNoDestinationsOnceTheGameIsWon() throws {
        let model = makeModel(resuming: try Game.won())
        XCTAssertEqual(model.destinations(forCardAt: top(.foundation(0), model), in: .foundation(0)), [])
    }

    func testEveryDestinationIsALegalMove() {
        let model = makeModel()
        for pile in PileID.allTableau {
            let count = model.state.pile(pile).count
            for index in 0 ..< count {
                for destination in model.destinations(forCardAt: index, in: pile) {
                    XCTAssertTrue(model.game.canMove(count: count - index, from: pile, to: destination))
                }
            }
        }
    }

    // MARK: moveCards

    func testMoveCardsPlaysTheChosenMove() {
        let model = makeModel()
        XCTAssertTrue(model.moveCards(
            from: Self.fiveOfHeartsColumn,
            index: top(Self.fiveOfHeartsColumn, model),
            to: Self.sixOfSpadesColumn
        ))
        XCTAssertEqual(model.state.pile(Self.sixOfSpadesColumn).last?.id, "5♥")
        XCTAssertEqual(model.moveCount, 1)
    }

    func testMoveCardsRejectsAnIllegalMove() {
        let model = makeModel()
        XCTAssertFalse(model.moveCards(from: .tableau(0), index: 0, to: .foundation(0)))
        XCTAssertFalse(model.moveCards(from: .tableau(0), index: 1, to: .tableau(1)), "past the top of the pile")
        XCTAssertEqual(model.moveCount, 0)
    }

    func testMoveCardsIsIgnoredWhileAutoCompleting() {
        let model = makeModel(resuming: Game.completable())
        model.autoComplete()
        XCTAssertFalse(model.moveCards(from: .tableau(0), index: top(.tableau(0), model), to: .foundation(3)))
        XCTAssertEqual(model.moveCount, 0)
    }
}
