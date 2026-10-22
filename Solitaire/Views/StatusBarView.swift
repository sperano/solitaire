import SwiftUI

/// Moves, time, score and the game controls.
struct StatusBarView: View {
    private static let itemSpacing: CGFloat = 12
    /// Moves, time and score shrink this far rather than wrap on narrow phones.
    private static let minimumStatScale: CGFloat = 0.7
    private static let horizontalPadding: CGFloat = 16
    private static let verticalPadding: CGFloat = 8

    let viewModel: GameViewModel
    @State private var isConfirmingNewGame = false

    var body: some View {
        HStack(spacing: Self.itemSpacing) {
            stats
            Spacer(minLength: 0)
            controls
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

    private var stats: some View {
        HStack(spacing: Self.itemSpacing) {
            stat(
                "\(viewModel.moveCount)", icon: "arrow.left.arrow.right",
                identifier: "movesLabel", spoken: "\(viewModel.moveCount) moves"
            )
            stat(viewModel.formattedTime, icon: "clock", identifier: "timeLabel", spoken: "Time \(viewModel.formattedTime)")
            if let score = viewModel.formattedScore {
                stat(
                    score, icon: viewModel.scoringMode == .vegas ? "dollarsign.circle" : "star",
                    identifier: "scoreLabel", spoken: "Score \(score)"
                )
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(Self.minimumStatScale)
    }

    private func stat(_ title: String, icon: String, identifier: String, spoken: String) -> some View {
        Label(title, systemImage: icon)
            .labelStyle(.titleAndIcon)
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier(identifier)
            .accessibilityLabel(spoken)
    }

    @ViewBuilder private var controls: some View {
        // Finish stays, disabled, while it runs, so the toolbar doesn't swap buttons mid-animation.
        if viewModel.canAutoComplete || viewModel.isAutoCompleting {
            Button("Finish", systemImage: "checkmark.circle") { viewModel.autoComplete() }
                .disabled(viewModel.isAutoCompleting)
                .accessibilityIdentifier("autoCompleteButton")
        } else {
            Button("Hint", systemImage: "lightbulb") { showHint() }
                .disabled(!viewModel.canHint)
                .accessibilityIdentifier("hintButton")
        }
        Button("Undo", systemImage: "arrow.uturn.backward") { viewModel.undo() }
            .disabled(!viewModel.canUndo)
            .accessibilityIdentifier("undoButton")
        Button("New Game", systemImage: "plus.circle") { requestNewGame() }
            .accessibilityIdentifier("newGameButton")
        Button("Settings", systemImage: "gearshape") { viewModel.isShowingSettings = true }
            .accessibilityIdentifier("settingsButton")
    }

    /// Every tap is announced, even when it repeats the hint already on show.
    private func showHint() {
        viewModel.showHint()
        if let hint = viewModel.hint {
            AccessibilityNotification.Announcement(HintAnnouncement.text(for: hint, in: viewModel.state)).post()
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
