import SwiftUI

/// Moves, time and the game controls.
struct StatusBarView: View {
    private static let itemSpacing: CGFloat = 16
    private static let horizontalPadding: CGFloat = 16
    private static let verticalPadding: CGFloat = 8

    let viewModel: GameViewModel
    @State private var isConfirmingNewGame = false

    var body: some View {
        HStack(spacing: Self.itemSpacing) {
            Label("\(viewModel.moveCount)", systemImage: "arrow.left.arrow.right")
                .labelStyle(.titleAndIcon)
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("movesLabel")
                .accessibilityLabel("\(viewModel.moveCount) moves")
            Label(viewModel.formattedTime, systemImage: "clock")
                .labelStyle(.titleAndIcon)
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("timeLabel")
                .accessibilityLabel("Time \(viewModel.formattedTime)")
            Spacer()
            if viewModel.canAutoComplete {
                Button("Finish", systemImage: "checkmark.circle") { viewModel.autoComplete() }
                    .accessibilityIdentifier("autoCompleteButton")
            }
            Button("Undo", systemImage: "arrow.uturn.backward") { viewModel.undo() }
                .disabled(!viewModel.canUndo)
                .accessibilityIdentifier("undoButton")
            Button("New Game", systemImage: "plus.circle") { requestNewGame() }
                .accessibilityIdentifier("newGameButton")
            Button("Settings", systemImage: "gearshape") { viewModel.isShowingSettings = true }
                .accessibilityIdentifier("settingsButton")
        }
        .labelStyle(.iconOnly)
        .font(.title3)
        .monospacedDigit()
        .foregroundStyle(.white)
        .padding(.horizontal, Self.horizontalPadding)
        .padding(.vertical, Self.verticalPadding)
        .confirmationDialog("Start a new game?", isPresented: $isConfirmingNewGame, titleVisibility: .visible) {
            Button("New Game", role: .destructive) { viewModel.newGame() }
                .accessibilityIdentifier("confirmNewGameButton")
        } message: {
            Text("The current game will be lost.")
        }
    }

    private func requestNewGame() {
        if viewModel.moveCount == 0 || viewModel.isWon {
            viewModel.newGame()
        } else {
            isConfirmingNewGame = true
        }
    }
}
