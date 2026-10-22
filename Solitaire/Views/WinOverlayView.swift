import SwiftUI

struct WinOverlayView: View {
    let viewModel: GameViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("You won!")
                    .font(.largeTitle.bold())
                Text("\(viewModel.moveCount) moves in \(viewModel.formattedTime)")
                    .font(.title3)
                    .accessibilityIdentifier("winSummary")
                Button("New Game") { viewModel.newGame() }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("winNewGameButton")
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .accessibilityIdentifier("winOverlay")
    }
}
