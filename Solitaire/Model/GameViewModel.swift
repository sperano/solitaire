import Foundation
import SolitaireKit

/// Drives the board: owns the game, the timer, the drag state and persistence, and reports
/// each finished or abandoned game to the statistics.
@MainActor
@Observable
final class GameViewModel {
    static let autoCompleteStepSeconds = 0.12
    /// How often the clock on show and the saved elapsed time are refreshed while the clock runs.
    static let clockTick = Duration.seconds(1)
    static let defaultHintDuration = Duration.seconds(3)

    private(set) var game: Game
    /// See `SavedGame.gameID`.
    private(set) var gameID: UInt64
    /// Bumped every `clockTick` while the clock runs, so whatever shows `elapsedSeconds` refreshes.
    private var clockTicks = 0
    var drag: DragInfo?
    /// The drag behind the last move, if a drop made it; the board flies its cards from there.
    private(set) var lastDrop: DragInfo?
    /// The clock pauses while Settings is open.
    var isShowingSettings = false {
        didSet { syncTimer() }
    }

    /// The "Start a new game?" dialog is up; see `requestNewGame()`.
    var isConfirmingNewGame = false
    private(set) var isAutoCompleting = false
    /// A winnable deal is being searched for; the board shows the previous game and ignores input.
    private(set) var isDealing = false
    /// The hint on show, cleared by the next move, undo or new game, or after `hintDuration`.
    private(set) var hint: Hint?
    /// How long a hint stays on the board when the player does nothing.
    var hintDuration = defaultHintDuration
    /// See `SavedGame.isStarted` and `SavedGame.isResultRecorded`.
    private(set) var isStarted: Bool
    private(set) var isResultRecorded: Bool

    let settings: GameSettings
    let statistics: StatisticsModel
    private let store: any GameStore
    private let haptics: any HapticPlayer
    private let fixedSeed: UInt64?
    private let clock: any GameClock
    /// Time the clock ran before its current run; the whole elapsed time while it is stopped.
    private var bankedTime: Duration
    /// `clock.now` when the current run started; nil while the clock is stopped or paused.
    private var runStart: Duration?
    /// The scene is active; the clock pauses in the background and in the app switcher.
    private var isAppActive = true
    private var timerTask: Task<Void, Never>?
    private var hintTask: Task<Void, Never>?
    private var dealTask: Task<Void, Never>?

    init(
        store: any GameStore, settings: GameSettings, statistics: StatisticsModel,
        haptics: any HapticPlayer = SilentHaptics(), fixedSeed: UInt64? = nil, clock: any GameClock = SystemGameClock()
    ) {
        self.store = store
        self.haptics = haptics
        self.settings = settings
        self.statistics = statistics
        self.fixedSeed = fixedSeed
        self.clock = clock
        let saved = store.load()
        game = saved?.game ?? Self.deal(seed: fixedSeed, settings: settings)
        gameID = saved?.gameID ?? Self.newGameID()
        bankedTime = .seconds(saved?.elapsedSeconds ?? 0)
        isStarted = saved?.isStarted ?? false
        isResultRecorded = saved?.isResultRecorded ?? false
        syncTimer()
        finishIfAutomatic()
        if saved == nil, fixedSeed == nil, settings.winnableDealsOnly {
            searchWinnableDeal(startingWith: game.state.seed)
        }
    }

    var state: GameState { game.state }
    /// Whole seconds the clock has run for this game: the banked time plus the current run.
    var elapsedSeconds: Int {
        // Read so that a view showing the time depends on the ticks and refreshes every second.
        _ = clockTicks
        let running = runStart.map { clock.now - $0 } ?? .zero
        return Int((bankedTime + running).components.seconds)
    }

    var isWon: Bool { game.isWon }
    var canUndo: Bool { game.canUndo && !isAutoCompleting && !isDealing }
    /// Player input is ignored while auto-complete plays the remaining cards or a deal is searched for.
    var acceptsInput: Bool { !isAutoCompleting && !game.isWon && !isDealing }
    var canAutoComplete: Bool { game.canAutoComplete && !isAutoCompleting }
    /// Hints are offered during play, except when the Finish button already shows the way.
    var canHint: Bool { acceptsInput && !game.canAutoComplete }
    var moveCount: Int { game.moveCount }
    var canDraw: Bool { game.canDraw }
    var scoringMode: ScoringMode { game.scoringMode }
    /// The seed of the current deal, which players see, share and type to play it again.
    var dealNumber: UInt64 { game.state.seed }

    /// The engine's score, plus the standard time bonus once a timed game is won.
    var score: Int {
        game.score + timeBonus
    }

    /// Nothing in untimed mode: the clock does not run, so there is no time to reward.
    var timeBonus: Int {
        isWon && settings.timed ? Scoring.timeBonus(mode: game.scoringMode, elapsedSeconds: elapsedSeconds) : 0
    }

    /// Points in standard scoring, dollars in Vegas, nil when the game is not scored.
    var formattedScore: String? {
        switch game.scoringMode {
        case .none: nil
        case .standard: "\(score)"
        case .vegas:
            if score < 0 {
                String(localized: "-$\(-score)", comment: "Vegas: a loss in dollars")
            } else {
                String(localized: "$\(score)", comment: "Vegas: dollars won")
            }
        }
    }

    var formattedTime: String { TimeFormat.minutesAndSeconds(elapsedSeconds) }

    // MARK: Actions

    /// Deals a new game: a fresh deal number, or with winnable deals only, one the solver wins
    /// (searched off the main actor; see `isDealing`). Abandoning a started game that is not won
    /// counts as a loss.
    func newGame() {
        closeCurrentGame()
        if let fixedSeed {
            install(Self.deal(seed: fixedSeed, settings: settings))
        } else if settings.winnableDealsOnly {
            searchWinnableDeal(startingWith: UInt64.random(in: GameState.dealNumberRange))
        } else {
            install(Self.deal(seed: nil, settings: settings))
        }
    }

    /// What the New Game button and its shortcut do: ask first when a started game would be lost;
    /// a won game, an untouched deal and a board still waiting for a deal (its game is already
    /// closed) start over at once.
    func requestNewGame() {
        if moveCount == 0 || isWon || isDealing {
            newGame()
        } else {
            isConfirmingNewGame = true
        }
    }

    /// Deals the current deal number again, in the current settings.
    func replayDeal() {
        playDeal(number: dealNumber)
    }

    /// Deals the game with that deal number, as it is: a deal asked for is never checked for winnability.
    func playDeal(number: UInt64) {
        closeCurrentGame()
        install(Self.deal(seed: number, settings: settings))
    }

    func draw() {
        guard acceptsInput else { return }
        if !perform(.draw) { feedback(.invalidMove) }
    }

    /// Tap on the card at `index` of `pile`: send it (and the run above it) to the best destination.
    func tapCard(in pile: PileID, index: Int) {
        let count = state.pile(pile).count - index
        guard acceptsInput, count >= 1 else { return }
        guard let destination = game.autoMoveDestination(count: count, from: pile) else {
            feedback(.invalidMove)
            return
        }
        perform(.move(from: pile, to: destination, count: count))
    }

    /// The dragged cards may be dropped on `destination`.
    func canDrop(on destination: PileID?) -> Bool {
        guard acceptsInput, let drag, let destination else { return false }
        return game.canMove(count: drag.count, from: drag.source, to: destination)
    }

    /// Drop the dragged cards on `destination`. Returns false when the move is illegal.
    @discardableResult
    func drop(on destination: PileID?) -> Bool {
        defer { drag = nil }
        guard acceptsInput, let drag, let destination else { return false }
        let moved = perform(.move(from: drag.source, to: destination, count: drag.count))
        if moved { lastDrop = drag } else { feedback(.invalidMove) }
        return moved
    }

    /// Moves the card at `index` of `pile`, with the run above it, to `destination`; VoiceOver's
    /// custom actions use it so the game is playable without dragging. Returns false when illegal.
    @discardableResult
    func moveCards(from pile: PileID, index: Int, to destination: PileID) -> Bool {
        let count = state.pile(pile).count - index
        guard acceptsInput, count >= 1 else { return false }
        return perform(.move(from: pile, to: destination, count: count))
    }

    func undo() {
        guard canUndo, game.undo() else { return }
        lastDrop = nil
        clearHint()
        syncTimer()
        persist()
    }

    func autoComplete() {
        guard canAutoComplete else { return }
        isAutoCompleting = true
        Task {
            while let move = game.nextAutoCompleteMove(), isAutoCompleting {
                perform(move)
                try? await Task.sleep(for: .seconds(Self.autoCompleteStepSeconds))
            }
            isAutoCompleting = false
        }
    }

    /// Shows the engine's suggested move, or that no useful move is left, for `hintDuration`.
    func showHint() {
        guard canHint else { return }
        clearHint()
        hint = game.suggestedMove().map(Hint.move) ?? .noUsefulMove
        hintTask = Task { [weak self, hintDuration] in
            try? await Task.sleep(for: hintDuration)
            guard !Task.isCancelled, let self else { return }
            hint = nil
        }
    }

    /// Turning on auto-finish while Finish is already offered takes effect when Settings closes,
    /// and so does turning the timer on or off.
    func settingsDismissed() {
        finishIfAutomatic()
        syncTimer()
    }

    /// The scene became active or left the foreground; the clock only runs while active.
    func setAppActive(_ active: Bool) {
        isAppActive = active
        syncTimer()
    }

    // MARK: Helpers

    /// A new game with the current settings; a Vegas game pays its buy-in from the carried balance.
    private static func deal(seed: UInt64?, settings: GameSettings) -> Game {
        Game(
            seed: seed ?? UInt64.random(in: GameState.dealNumberRange),
            drawMode: settings.drawMode,
            scoringMode: settings.scoringMode,
            carriedBalance: settings.carriedVegasBalance
        )
    }

    /// Ends the game on the board: stops the clock and any search, records the loss of a started
    /// game and keeps a Vegas balance for the next game. The board keeps showing it until `install`.
    private func closeCurrentGame() {
        stopClock()
        dealTask?.cancel()
        dealTask = nil
        isDealing = false
        isAutoCompleting = false
        drag = nil
        lastDrop = nil
        clearHint()
        if isStarted, !isResultRecorded {
            statistics.recordLoss(gameID: gameID, drawMode: game.drawMode)
            isResultRecorded = true
        }
        if game.scoringMode == .vegas, settings.carryVegasBalance {
            settings.vegasBalance = game.score
        }
    }

    /// Puts a new game on the board and saves it.
    private func install(_ newGame: Game) {
        game = newGame
        gameID = Self.newGameID()
        bankedTime = .zero
        runStart = nil
        isStarted = false
        isResultRecorded = false
        persist()
    }

    /// Looks for a winnable deal off the main actor, trying `first` and then random deal numbers,
    /// and installs it; until then `isDealing` is true. A new game or deal number cancels the search.
    private func searchWinnableDeal(startingWith first: UInt64) {
        isDealing = true
        let (drawMode, scoringMode, carriedBalance) = (
            settings.drawMode,
            settings.scoringMode,
            settings.carriedVegasBalance
        )
        dealTask = Task { [weak self] in
            let found = await DealSearch.winnableDeal(
                startingWith: first, drawMode: drawMode, scoringMode: scoringMode, carriedBalance: carriedBalance
            )
            guard let self, let found, !Task.isCancelled else { return }
            isDealing = false
            // The deal shown at launch is kept, and now saved, when it turns out to be winnable.
            if found.seed == game.state.seed, game.moveCount == 0 {
                persist()
            } else {
                install(Game(state: found))
            }
        }
    }

    private static func newGameID() -> UInt64 { .random(in: .min ... .max) }

    @discardableResult
    private func perform(_ move: Move) -> Bool {
        lastDrop = nil
        do {
            try game.perform(move)
        } catch {
            return false
        }
        isStarted = true
        clearHint()
        syncTimer()
        recordWinIfNeeded()
        persist()
        // Auto-complete plays many moves in a row; only its last one, the win, is felt.
        if game.isWon {
            feedback(.win)
        } else if !isAutoCompleting {
            feedback(.move)
        }
        finishIfAutomatic()
        return true
    }

    private func feedback(_ event: HapticEvent) {
        if settings.haptics { haptics.play(event) }
    }

    /// Starts auto-complete when the setting asks for it and the position allows it; it does
    /// nothing while auto-complete runs, and undo never calls it, so undoing a finish sticks.
    private func finishIfAutomatic() {
        if settings.autoFinish { autoComplete() }
    }

    private func clearHint() {
        hintTask?.cancel()
        hintTask = nil
        hint = nil
    }

    /// Counts a win once, with the moves it took and, in timed mode, the time.
    private func recordWinIfNeeded() {
        guard game.isWon, !isResultRecorded else { return }
        statistics.recordWin(
            gameID: gameID, drawMode: game.drawMode, seconds: settings.timed ? elapsedSeconds : nil,
            moves: game.moveCount
        )
        isResultRecorded = true
    }

    private func persist() {
        store.save(SavedGame(
            game: game, gameID: gameID, elapsedSeconds: elapsedSeconds,
            isStarted: isStarted, isResultRecorded: isResultRecorded
        ))
    }

    /// The clock runs from the first move until the game is won, except while the app is in the
    /// background, Settings is open, the game is untimed or a deal is being searched for. Pausing
    /// saves the time so far, so a game killed in the background resumes from the right value.
    private func syncTimer() {
        let shouldRun = game.moveCount > 0 && !game.isWon && !isDealing
            && isAppActive && !isShowingSettings && settings.timed
        if shouldRun {
            startClock()
        } else if stopClock() {
            persist()
        }
    }

    private func startClock() {
        if runStart == nil { runStart = clock.now }
        guard timerTask == nil else { return }
        timerTask = Task { [weak self, clock] in
            while !Task.isCancelled {
                try? await clock.sleep(for: Self.clockTick)
                guard !Task.isCancelled, let self else { return }
                clockTicks &+= 1
                persist()
            }
        }
    }

    /// Banks the current run and stops the ticks. Returns false when the clock was not running.
    @discardableResult
    private func stopClock() -> Bool {
        timerTask?.cancel()
        timerTask = nil
        guard let runStart else { return false }
        bankedTime += clock.now - runStart
        self.runStart = nil
        return true
    }
}
