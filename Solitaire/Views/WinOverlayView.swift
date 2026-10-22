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
                Button("New Game") { viewModel.newGame() }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("winNewGameButton")
            }
            .padding(Self.padding)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
        }
        .accessibilityIdentifier("winOverlay")
    }
}
