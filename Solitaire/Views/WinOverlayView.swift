import SwiftUI

struct WinOverlayView: View {
    private static let dimOpacity = 0.45
    private static let spacing: CGFloat = 16
    private static let padding: CGFloat = 32
    private static let cornerRadius: CGFloat = 20

    let viewModel: GameViewModel
    /// The cascade for a screen of the given size, played between the dimmed board and the panel;
    /// nil under Reduce Motion.
    let celebration: (CGSize) -> WinCascadeView?

    var body: some View {
        ZStack {
            Color.black.opacity(Self.dimOpacity).ignoresSafeArea()
            GeometryReader { proxy in celebration(proxy.size) }
            VStack(spacing: Self.spacing) {
                Text("You won!")
                    .font(.largeTitle.bold())
                Text(summary)
                    .font(.title3)
                    .accessibilityIdentifier("winSummary")
                if let score = viewModel.formattedScore {
                    Text(scoreSummary(score))
                        .font(.title3)
                        .accessibilityIdentifier("winScore")
                }
                Button("New Game") { viewModel.newGame() }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("winNewGameButton")
            }
            .padding(Self.padding)
            // Opaque: cascading cards pass behind the panel and must not show through its text.
            .background(.background, in: RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
        }
        // A container, so the identifier doesn't replace those of the texts and button inside it.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("winOverlay")
    }

    /// The moves, and the time when the game was timed.
    private var summary: String {
        let moves = "\(viewModel.moveCount) moves"
        return viewModel.settings.timed ? "\(moves) in \(viewModel.formattedTime)" : moves
    }

    private func scoreSummary(_ score: String) -> String {
        let bonus = viewModel.timeBonus
        return bonus > 0 ? "Score \(score), including a time bonus of \(bonus)" : "Score \(score)"
    }
}
