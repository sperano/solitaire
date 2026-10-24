import XCTest
@testable import SolitaireKit

final class ScoringTests: XCTestCase {
    private static let startingScore = 20
    private static let carriedBalance = 100
    private static let longGameSeconds = 100
    private static let unlimitedRecycleCount = 5
    /// Enough to pay the draw-1 recycle penalty in full, and not enough.
    private static let richScore = 150
    private static let poorScore = 30

    private func applied(_ move: Move, to state: GameState) throws -> GameState {
        var next = state
        try next.apply(move)
        return next
    }

    private func standard(score: Int = startingScore, drawMode: DrawMode = .one, tableau: [[Card]] = [],
                          stock: [Card] = [], waste: [Card] = [], foundations: [[Card]] = []) -> GameState
    {
        blankState(drawMode: drawMode, scoringMode: .standard, score: score,
                   tableau: tableau, stock: stock, waste: waste, foundations: foundations)
    }

    private func vegas(drawMode: DrawMode = .one, tableau: [[Card]] = [], stock: [Card] = [],
                       waste: [Card] = [], foundations: [[Card]] = []) -> GameState
    {
        blankState(drawMode: drawMode, scoringMode: .vegas,
                   tableau: tableau, stock: stock, waste: waste, foundations: foundations)
    }

    private func points(_ move: Move, _ state: GameState) throws -> Int {
        try applied(move, to: state).score - state.score
    }

    // MARK: Standard

    func testStandardGameStartsAtZero() {
        XCTAssertEqual(GameState.deal(seed: 1, drawMode: .one, scoringMode: .standard).score, 0)
    }

    func testWasteToTableauScoresFive() throws {
        let state = standard(tableau: [[card(.eight, .spades)]], waste: [card(.seven, .hearts)])
        XCTAssertEqual(try points(.move(from: .waste, to: .tableau(0), count: 1), state), Scoring.wasteToTableauPoints)
    }

    func testWasteToFoundationScoresTen() throws {
        let state = standard(waste: [card(.ace, .hearts)])
        XCTAssertEqual(try points(.move(from: .waste, to: .foundation(0), count: 1), state), Scoring.toFoundationPoints)
    }

    func testTableauToFoundationScoresTen() throws {
        let state = standard(tableau: [[card(.ace, .hearts)]])
        XCTAssertEqual(
            try points(.move(from: .tableau(0), to: .foundation(0), count: 1), state),
            Scoring.toFoundationPoints
        )
    }

    func testMoveThatTurnsOverATableauCardAddsFive() throws {
        let toFoundation = standard(tableau: [[card(.two, .clubs, up: false), card(.ace, .hearts)]])
        XCTAssertEqual(
            try points(.move(from: .tableau(0), to: .foundation(0), count: 1), toFoundation),
            Scoring.toFoundationPoints + Scoring.flipPoints
        )
        let toTableau = standard(tableau: [
            [card(.king, .clubs, up: false), card(.seven, .hearts)],
            [card(.eight, .spades)],
        ])
        XCTAssertEqual(try points(.move(from: .tableau(0), to: .tableau(1), count: 1), toTableau), Scoring.flipPoints)
    }

    func testTableauToTableauWithoutFlipScoresNothing() throws {
        let state = standard(tableau: [[card(.king, .clubs), card(.seven, .hearts)], [card(.eight, .spades)]])
        XCTAssertEqual(try points(.move(from: .tableau(0), to: .tableau(1), count: 1), state), 0)
    }

    func testFoundationToTableauCostsFifteen() throws {
        let state = standard(
            tableau: [[card(.three, .spades)]],
            foundations: [[card(.ace, .hearts), card(.two, .hearts)]]
        )
        XCTAssertEqual(
            try points(.move(from: .foundation(0), to: .tableau(0), count: 1), state), Scoring.foundationToTableauPoints
        )
    }

    func testStandardScoreNeverDropsBelowZero() throws {
        let state = standard(
            score: 0,
            tableau: [[card(.three, .spades)]],
            foundations: [[card(.ace, .hearts), card(.two, .hearts)]]
        )
        XCTAssertEqual(try applied(.move(from: .foundation(0), to: .tableau(0), count: 1), to: state).score, 0)
    }

    func testRecyclingInDrawOneCostsAHundredDownToZero() throws {
        let rich = standard(score: Self.richScore, waste: [card(.five, .clubs)])
        XCTAssertEqual(try applied(.draw, to: rich).score, Self.richScore + Scoring.drawOneRecyclePoints)
        let poor = standard(score: Self.poorScore, waste: [card(.five, .clubs)])
        XCTAssertEqual(try applied(.draw, to: poor).score, 0)
    }

    func testRecyclingInDrawThreeAndDrawingAreFree() throws {
        let recycle = standard(drawMode: .three, waste: [card(.five, .clubs)])
        XCTAssertEqual(try points(.draw, recycle), 0)
        let draw = standard(stock: [card(.five, .clubs, up: false)])
        XCTAssertEqual(try points(.draw, draw), 0)
    }

    func testStandardAndUnscoredGamesRecycleWithoutLimit() throws {
        for mode in [ScoringMode.none, .standard] {
            var state = blankState(scoringMode: mode, waste: [card(.five, .clubs)])
            XCTAssertNil(state.remainingRecycles)
            for _ in 0 ..< Self.unlimitedRecycleCount {
                try state.apply(.draw)
                try state.apply(.draw)
            }
            XCTAssertEqual(state.recycleCount, Self.unlimitedRecycleCount)
        }
    }

    // MARK: No scoring

    func testUnscoredGameStaysAtZero() throws {
        var state = blankState(
            tableau: [[card(.two, .clubs, up: false), card(.ace, .hearts)]],
            waste: [card(.five, .clubs)]
        )
        try state.apply(.move(from: .tableau(0), to: .foundation(0), count: 1))
        try state.apply(.draw)
        XCTAssertEqual(state.score, 0)
    }

    // MARK: Vegas

    func testVegasGameStartsWithTheBuyInTakenFromTheCarriedBalance() {
        XCTAssertEqual(GameState.deal(seed: 1, drawMode: .one, scoringMode: .vegas).score, -Scoring.vegasBuyIn)
        XCTAssertEqual(
            GameState.deal(seed: 1, drawMode: .one, scoringMode: .vegas, carriedBalance: Self.carriedBalance).score,
            Self.carriedBalance - Scoring.vegasBuyIn
        )
    }

    func testCarriedBalanceIsIgnoredOutsideVegas() {
        let state = GameState.deal(seed: 1, drawMode: .one, scoringMode: .standard, carriedBalance: Self.carriedBalance)
        XCTAssertEqual(state.score, 0)
    }

    func testVegasPaysFivePerCardOnAFoundation() throws {
        let fromWaste = vegas(waste: [card(.ace, .hearts)])
        XCTAssertEqual(
            try points(.move(from: .waste, to: .foundation(0), count: 1), fromWaste),
            Scoring.vegasPointsPerFoundationCard
        )
        let fromTableau = vegas(tableau: [[card(.two, .clubs, up: false), card(.ace, .hearts)]])
        XCTAssertEqual(
            try points(.move(from: .tableau(0), to: .foundation(0), count: 1), fromTableau),
            Scoring.vegasPointsPerFoundationCard,
            "turning a card over earns nothing in Vegas"
        )
    }

    func testVegasTakesFiveBackWhenACardLeavesAFoundation() throws {
        let state = vegas(tableau: [[card(.three, .spades)]], foundations: [[card(.ace, .hearts), card(.two, .hearts)]])
        XCTAssertEqual(
            try points(.move(from: .foundation(0), to: .tableau(0), count: 1), state),
            -Scoring.vegasPointsPerFoundationCard
        )
    }

    func testVegasIgnoresMovesThatDoNotTouchAFoundation() throws {
        let state = vegas(tableau: [[card(.eight, .spades)]], waste: [card(.seven, .hearts)])
        XCTAssertEqual(try points(.move(from: .waste, to: .tableau(0), count: 1), state), 0)
        XCTAssertEqual(try points(.draw, vegas(stock: [card(.five, .clubs, up: false)])), 0)
        XCTAssertEqual(try points(.draw, vegas(drawMode: .three, waste: [card(.five, .clubs)])), 0, "recycling is free")
    }

    func testVegasScoreMayGoNegative() throws {
        let state = vegas(tableau: [[card(.two, .spades)]], foundations: [[card(.ace, .hearts)]])
        let next = try applied(.move(from: .foundation(0), to: .tableau(0), count: 1), to: state)
        XCTAssertEqual(next.score, -Scoring.vegasBuyIn - Scoring.vegasPointsPerFoundationCard)
    }

    func testVegasDrawOneAllowsASinglePass() {
        let state = vegas(waste: [card(.five, .clubs)])
        XCTAssertEqual(state.remainingRecycles, 0)
        assertThrows(.noPassesLeft, state, .draw)
    }

    func testVegasDrawThreeAllowsThreePasses() throws {
        var state = vegas(drawMode: .three, waste: [card(.five, .clubs)])
        let recycles = Scoring.vegasDrawThreePasses - 1
        for done in 0 ..< recycles {
            XCTAssertEqual(state.remainingRecycles, recycles - done)
            try state.apply(.draw)
            try state.apply(.draw)
        }
        XCTAssertEqual(state.remainingRecycles, 0)
        assertThrows(.noPassesLeft, state, .draw)
    }

    func testEmptyStockAndWasteStillReportNothingToDraw() {
        assertThrows(.nothingToDraw, vegas(), .draw)
    }

    // MARK: Time bonus

    func testTimeBonusDividesSevenHundredThousandBySeconds() {
        XCTAssertEqual(
            Scoring.timeBonus(mode: .standard, elapsedSeconds: Self.longGameSeconds),
            Scoring.timeBonusNumerator / Self.longGameSeconds
        )
        XCTAssertEqual(
            Scoring.timeBonus(mode: .standard, elapsedSeconds: Scoring.timeBonusMinimumSeconds),
            Scoring.timeBonusNumerator / Scoring.timeBonusMinimumSeconds
        )
    }

    func testNoTimeBonusForShortGamesOrOtherModes() {
        XCTAssertEqual(Scoring.timeBonus(mode: .standard, elapsedSeconds: Scoring.timeBonusMinimumSeconds - 1), 0)
        XCTAssertEqual(Scoring.timeBonus(mode: .standard, elapsedSeconds: 0), 0)
        XCTAssertEqual(Scoring.timeBonus(mode: .vegas, elapsedSeconds: Self.longGameSeconds), 0)
        XCTAssertEqual(Scoring.timeBonus(mode: .none, elapsedSeconds: Self.longGameSeconds), 0)
    }

    func testVegasPassesByDrawMode() {
        XCTAssertEqual(Scoring.vegasPasses(drawMode: .one), Scoring.vegasDrawOnePasses)
        XCTAssertEqual(Scoring.vegasPasses(drawMode: .three), Scoring.vegasDrawThreePasses)
    }

    func testRecycleLimitOnlyAppliesToVegas() {
        XCTAssertEqual(Scoring.recycleLimit(mode: .vegas, drawMode: .one), Scoring.vegasDrawOnePasses - 1)
        XCTAssertEqual(Scoring.recycleLimit(mode: .vegas, drawMode: .three), Scoring.vegasDrawThreePasses - 1)
        XCTAssertNil(Scoring.recycleLimit(mode: .standard, drawMode: .one))
        XCTAssertNil(Scoring.recycleLimit(mode: .none, drawMode: .three))
    }

    // MARK: Score range

    func testExtremeCarriedBalanceIsClampedInsteadOfOverflowing() {
        let low = GameState.deal(seed: 1, drawMode: .one, scoringMode: .vegas, carriedBalance: .min)
        XCTAssertEqual(low.score, Scoring.scoreRange.lowerBound)
        let high = GameState.deal(seed: 1, drawMode: .one, scoringMode: .vegas, carriedBalance: .max)
        XCTAssertEqual(high.score, Scoring.scoreRange.upperBound - Scoring.vegasBuyIn)
        XCTAssertTrue(low.isValidPosition && high.isValidPosition)
    }

    func testScoreUpdatesStayInsideTheScoreRange() throws {
        var state = vegas(waste: [card(.ace, .hearts)])
        state.score = Scoring.scoreRange.upperBound
        XCTAssertEqual(
            try applied(.move(from: .waste, to: .foundation(0), count: 1), to: state).score,
            Scoring.scoreRange.upperBound
        )
        state.score = .max
        XCTAssertEqual(
            try applied(.move(from: .waste, to: .foundation(0), count: 1), to: state).score,
            Scoring.scoreRange.upperBound
        )
    }
}
