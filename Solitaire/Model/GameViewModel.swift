import Foundation
import SolitaireKit

/// Drives the board: owns the game, the timer, the drag state and persistence.
@MainActor
@Observable
final class GameViewModel {
    static let autoCompleteStepNanoseconds: UInt64 = 120_000_000
    private static let timerTickNanoseconds: UInt64 = 1_000_000_000

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
            game = Game(seed: fixedSeed ?? UInt64.random(in: .min ... .max), drawMode: settings.drawMode)
            elapsedSeconds = 0
        }
        syncTimer()
    }

    var state: GameState { game.state }
    var isWon: Bool { game.isWon }
    var canUndo: Bool { game.canUndo && !isAutoCompleting }
    var canAutoComplete: Bool { game.canAutoComplete && !isAutoCompleting }
    var moveCount: Int { game.moveCount }

    var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: Actions

    func newGame() {
        timerTask?.cancel()
        isAutoCompleting = false
        drag = nil
        game = Game(seed: fixedSeed ?? UInt64.random(in: .min ... .max), drawMode: settings.drawMode)
        elapsedSeconds = 0
        persist()
    }

    func draw() {
        perform(.draw)
    }

    /// Tap on the card at `index` of `pile`: send it (and the run above it) to the best destination.
    func tapCard(in pile: PileID, index: Int) {
        let count = state.pile(pile).count - index
        guard count >= 1, let destination = game.autoMoveDestination(count: count, from: pile) else { return }
        perform(.move(from: pile, to: destination, count: count))
    }

    /// Drop the dragged cards on `destination`. Returns false when the move is illegal.
    @discardableResult
    func drop(on destination: PileID?) -> Bool {
        defer { drag = nil }
        guard let drag, let destination else { return false }
        return perform(.move(from: drag.source, to: destination, count: drag.count))
    }

    func undo() {
        guard canUndo, game.undo() else { return }
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
            timerTask?.cancel()
            timerTask = nil
            return
        }
        guard timerTask == nil else { return }
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: Self.timerTickNanoseconds)
                guard !Task.isCancelled, let self else { return }
                elapsedSeconds += 1
            }
        }
    }
}
