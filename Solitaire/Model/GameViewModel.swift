import Foundation
import SolitaireKit

/// Drives the board: owns the game, the timer, the drag state and persistence, and reports
/// each finished or abandoned game to the statistics.
@MainActor
@Observable
final class GameViewModel {
    static let autoCompleteStepSeconds = 0.12
    private static let timerTickNanoseconds: UInt64 = 1_000_000_000
    static let defaultHintDuration = Duration.seconds(3)

    private(set) var game: Game
    /// See `SavedGame.gameID`.
    private(set) var gameID: UInt64
    private(set) var elapsedSeconds: Int
    var drag: DragInfo?
    /// The drag behind the last move, if a drop made it; the board flies its cards from there.
    private(set) var lastDrop: DragInfo?
    var isShowingSettings = false
    private(set) var isAutoCompleting = false
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
    private var timerTask: Task<Void, Never>?
    private var hintTask: Task<Void, Never>?

    init(
        store: any GameStore, settings: GameSettings, statistics: StatisticsModel,
        haptics: any HapticPlayer = SilentHaptics(), fixedSeed: UInt64? = nil
    ) {
        self.store = store
        self.haptics = haptics
        self.settings = settings
        self.statistics = statistics
        self.fixedSeed = fixedSeed
        let saved = store.load()
        game = saved?.game ?? Self.deal(seed: fixedSeed, settings: settings)
        gameID = saved?.gameID ?? Self.newGameID()
        elapsedSeconds = saved?.elapsedSeconds ?? 0
        isStarted = saved?.isStarted ?? false
        isResultRecorded = saved?.isResultRecorded ?? false
        syncTimer()
        finishIfAutomatic()
    }

    var state: GameState { game.state }
    var isWon: Bool { game.isWon }
    var canUndo: Bool { game.canUndo && !isAutoCompleting }
    /// Player input is ignored while auto-complete plays the remaining cards.
    var acceptsInput: Bool { !isAutoCompleting && !game.isWon }
    var canAutoComplete: Bool { game.canAutoComplete && !isAutoCompleting }
    /// Hints are offered during play, except when the Finish button already shows the way.
    var canHint: Bool { acceptsInput && !game.canAutoComplete }
    var moveCount: Int { game.moveCount }
    var canDraw: Bool { game.canDraw }
    var scoringMode: ScoringMode { game.scoringMode }

    /// The engine's score, plus the standard time bonus once the game is won.
    var score: Int {
        game.score + timeBonus
    }

    var timeBonus: Int {
        isWon ? Scoring.timeBonus(mode: game.scoringMode, elapsedSeconds: elapsedSeconds) : 0
    }

    /// Points in standard scoring, dollars in Vegas, nil when the game is not scored.
    var formattedScore: String? {
        switch game.scoringMode {
        case .none: nil
        case .standard: "\(score)"
        case .vegas: score < 0 ? "-$\(-score)" : "$\(score)"
        }
    }

    var formattedTime: String { TimeFormat.minutesAndSeconds(elapsedSeconds) }

    // MARK: Actions

    /// Deals a new game. Abandoning a started game that is not won counts as a loss.
    func newGame() {
        stopTimer()
        isAutoCompleting = false
        drag = nil
        lastDrop = nil
        clearHint()
        if isStarted, !isResultRecorded {
            statistics.recordLoss(gameID: gameID, drawMode: game.drawMode)
        }
        if game.scoringMode == .vegas, settings.carryVegasBalance {
            settings.vegasBalance = game.score
        }
        game = Self.deal(seed: fixedSeed, settings: settings)
        gameID = Self.newGameID()
        elapsedSeconds = 0
        isStarted = false
        isResultRecorded = false
        persist()
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

    /// Turning on auto-finish while Finish is already offered takes effect when Settings closes.
    func settingsDismissed() {
        finishIfAutomatic()
    }

    // MARK: Helpers

    /// A new game with the current settings; a Vegas game pays its buy-in from the carried balance.
    private static func deal(seed: UInt64?, settings: GameSettings) -> Game {
        Game(
            seed: seed ?? UInt64.random(in: .min ... .max),
            drawMode: settings.drawMode,
            scoringMode: settings.scoringMode,
            carriedBalance: settings.carriedVegasBalance
        )
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

    /// Counts a win once, with the time and moves it took.
    private func recordWinIfNeeded() {
        guard game.isWon, !isResultRecorded else { return }
        statistics.recordWin(gameID: gameID, drawMode: game.drawMode, seconds: elapsedSeconds, moves: game.moveCount)
        isResultRecorded = true
    }

    private func persist() {
        store.save(SavedGame(
            game: game, gameID: gameID, elapsedSeconds: elapsedSeconds,
            isStarted: isStarted, isResultRecorded: isResultRecorded
        ))
    }

    /// The clock runs from the first move until the game is won.
    private func syncTimer() {
        if game.isWon || game.moveCount == 0 {
            stopTimer()
            return
        }
        guard timerTask == nil else { return }
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: Self.timerTickNanoseconds)
                guard !Task.isCancelled, let self else { return }
                elapsedSeconds += 1
                persist()
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
}
