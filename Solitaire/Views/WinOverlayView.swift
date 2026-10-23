import SwiftUI

struct WinOverlayView: View {
    private static let dimOpacity = 0.45
    private static let spacing: CGFloat = 16
    private static let padding: CGFloat = 32
    private static let cornerRadius: CGFloat = 20

    let viewModel: GameViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(Self.dimOpacity).ignoresSafeArea()
            VStack(spacing: Self.spacing) {
                Text("You won!")
                    .font(.largeTitle.bold())
                Text("\(viewModel.moveCount) moves in \(viewModel.formattedTime)")
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
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
        }
        // A container, so the identifier doesn't replace those of the texts and button inside it.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("winOverlay")
    }

    private func scoreSummary(_ score: String) -> String {
        let bonus = viewModel.timeBonus
        return bonus > 0 ? "Score \(score), including a time bonus of \(bonus)" : "Score \(score)"
    }
}
