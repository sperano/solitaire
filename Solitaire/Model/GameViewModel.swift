import Foundation
import SolitaireKit

/// Drives the board: owns the game, the timer, the drag state and persistence.
@MainActor
@Observable
final class GameViewModel {
    static let autoCompleteStepNanoseconds: UInt64 = 120_000_000
    private static let timerTickNanoseconds: UInt64 = 1_000_000_000
    private static let secondsPerMinute = 60

    private(set) var game: Game
    private(set) var elapsedSeconds: Int
    var drag: DragInfo?
    var isShowingSettings = false
    private(set) var isAutoCompleting = false

    let settings: GameSettings
    private let store: any GameStore
    private let fixedSeed: UInt64?
    private var timerTask: Task<Void, Never>?

    init(store: any GameStore, settings: GameSettings, fixedSeed: UInt64? = nil) {
        self.store = store
        self.settings = settings
        self.fixedSeed = fixedSeed
        if let saved = store.load() {
            game = saved.game
            elapsedSeconds = saved.elapsedSeconds
        } else {
            game = Self.deal(seed: fixedSeed, settings: settings)
            elapsedSeconds = 0
        }
        syncTimer()
    }

    var state: GameState { game.state }
    var isWon: Bool { game.isWon }
    var canUndo: Bool { game.canUndo && !isAutoCompleting }
    /// Player input is ignored while auto-complete plays the remaining cards.
    var acceptsInput: Bool { !isAutoCompleting && !game.isWon }
    var canAutoComplete: Bool { game.canAutoComplete && !isAutoCompleting }
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

    var formattedTime: String {
        let minutes = elapsedSeconds / Self.secondsPerMinute
        let seconds = elapsedSeconds % Self.secondsPerMinute
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: Actions

    func newGame() {
        stopTimer()
        isAutoCompleting = false
        drag = nil
        if game.scoringMode == .vegas, settings.carryVegasBalance {
            settings.vegasBalance = game.score
        }
        game = Self.deal(seed: fixedSeed, settings: settings)
        elapsedSeconds = 0
        persist()
    }

    func draw() {
        guard acceptsInput else { return }
        perform(.draw)
    }

    /// Tap on the card at `index` of `pile`: send it (and the run above it) to the best destination.
    func tapCard(in pile: PileID, index: Int) {
        let count = state.pile(pile).count - index
        guard acceptsInput, count >= 1, let destination = game.autoMoveDestination(count: count, from: pile) else { return }
        perform(.move(from: pile, to: destination, count: count))
    }

    /// Drop the dragged cards on `destination`. Returns false when the move is illegal.
    @discardableResult
    func drop(on destination: PileID?) -> Bool {
        defer { drag = nil }
        guard acceptsInput, let drag, let destination else { return false }
        return perform(.move(from: drag.source, to: destination, count: drag.count))
    }

    func undo() {
        guard canUndo, game.undo() else { return }
        syncTimer()
        persist()
    }

    func autoComplete() {
        guard canAutoComplete else { return }
        isAutoCompleting = true
        Task {
            while let move = game.nextAutoCompleteMove(), isAutoCompleting {
                perform(move)
                try? await Task.sleep(nanoseconds: Self.autoCompleteStepNanoseconds)
            }
            isAutoCompleting = false
        }
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

    @discardableResult
    private func perform(_ move: Move) -> Bool {
        do {
            try game.perform(move)
        } catch {
            return false
        }
        syncTimer()
        persist()
        return true
    }

    private func persist() {
        store.save(SavedGame(game: game, elapsedSeconds: elapsedSeconds))
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
