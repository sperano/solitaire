import SwiftUI

/// Hardware keyboard shortcuts, listed in the iPad's shortcut overlay (hold ⌘): ⌘Z undoes, ⇧⌘Z
/// redoes, ⌘N starts a new game (asking first, like the button) and the space bar draws. None of
/// them acts while Settings is open, so typing a deal number there never moves a card.
struct GameCommands: Commands {
    static let undoKey: KeyEquivalent = "z"
    static let newGameKey: KeyEquivalent = "n"
    static let drawKey: KeyEquivalent = .space

    @Bindable var viewModel: GameViewModel

    var body: some Commands {
        CommandGroup(replacing: .undoRedo) {
            Button("Undo") { viewModel.undo() }
                .keyboardShortcut(Self.undoKey, modifiers: .command)
                .disabled(viewModel.isShowingSettings || !viewModel.canUndo)
            Button("Redo") { viewModel.redo() }
                .keyboardShortcut(Self.undoKey, modifiers: [.command, .shift])
                .disabled(viewModel.isShowingSettings || !viewModel.canRedo)
        }
        CommandGroup(replacing: .newItem) {
            Button("New Game") { viewModel.requestNewGame() }
                .keyboardShortcut(Self.newGameKey, modifiers: .command)
                .disabled(viewModel.isShowingSettings)
        }
        CommandMenu("Game") {
            Button("Draw") { viewModel.draw() }
                .keyboardShortcut(Self.drawKey, modifiers: [])
                .disabled(viewModel.isShowingSettings || !viewModel.acceptsInput)
        }
    }
}
