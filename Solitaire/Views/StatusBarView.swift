import SwiftUI

/// Moves, time, score and the game controls.
struct StatusBarView: View {
    private static let itemSpacing: CGFloat = 12
    private static let horizontalPadding: CGFloat = 16
    private static let verticalPadding: CGFloat = 8
    /// The smallest tap target Apple's guidelines allow.
    static let minimumHitSize: CGFloat = 44

    @Bindable var viewModel: GameViewModel

    var body: some View {
        layout
            .labelStyle(.iconOnly)
            .font(.title3)
            .foregroundStyle(.white)
            .padding(.horizontal, Self.horizontalPadding)
            .padding(.vertical, Self.verticalPadding)
            .confirmationDialog(
                "Start a new game?",
                isPresented: $viewModel.isConfirmingNewGame,
                titleVisibility: .visible
            ) {
                Button("New Game", role: .destructive) { viewModel.newGame() }
                    .accessibilityIdentifier("confirmNewGameButton")
                Button("Replay This Deal") { viewModel.replayDeal() }
                    .accessibilityIdentifier("replayDealButton")
            } message: {
                Text("The current game will be lost.")
            }
    }

    @ViewBuilder private var stats: some View {
        stat(
            "\(viewModel.moveCount)", icon: "arrow.left.arrow.right",
            identifier: "movesLabel", spoken: CountPhrase.moves(viewModel.moveCount)
        )
        if viewModel.settings.timed {
            stat(
                viewModel.formattedTime,
                icon: "clock",
                identifier: "timeLabel",
                spoken: String(localized: "Time \(viewModel.formattedTime)", comment: "Spoken time")
            )
        }
        if let score = viewModel.formattedScore {
            stat(
                score, icon: viewModel.scoringMode == .vegas ? "dollarsign.circle" : "star",
                identifier: "scoreLabel", spoken: String(localized: "Score \(score)", comment: "The score")
            )
        }
    }

    /// One row when everything fits; otherwise, as with large text, the stats get a row of their own,
    /// and stack when even that row is too narrow. Nothing shrinks or gets cut off.
    private var layout: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Self.itemSpacing) {
                statsRow
                Spacer(minLength: 0)
                controlsRow
            }
            VStack(alignment: .leading, spacing: 0) {
                ViewThatFits(in: .horizontal) {
                    statsRow
                    VStack(alignment: .leading) { stats }
                }
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    controlsRow
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: Self.itemSpacing) { stats }
    }

    private var controlsRow: some View {
        HStack(spacing: 0) { controls }
            .buttonStyle(HitTargetButtonStyle())
    }

    private func stat(_ title: String, icon: String, identifier: String, spoken: String) -> some View {
        Label {
            Text(title).monospacedDigit()
        } icon: {
            Image(systemName: icon)
        }
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
        Button("New Game", systemImage: "plus.circle") { viewModel.requestNewGame() }
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
}

/// Tap targets at least `minimumHitSize` square, so the small toolbar icons are easy to hit.
private struct HitTargetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HitTargetLabel(configuration: configuration)
    }
}

private struct HitTargetLabel: View {
    private static let pressedOpacity = 0.5
    private static let disabledOpacity = 0.35

    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .frame(minWidth: StatusBarView.minimumHitSize, minHeight: StatusBarView.minimumHitSize)
            .contentShape(Rectangle())
            .opacity(isEnabled ? (configuration.isPressed ? Self.pressedOpacity : 1) : Self.disabledOpacity)
    }
}
