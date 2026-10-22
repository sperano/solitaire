import SolitaireKit
import SwiftUI

struct GameView: View {
    private static let rowSpacing: CGFloat = 12

    @Bindable var viewModel: GameViewModel
    @State private var pileFrames: [PileID: CGRect] = [:]

    var body: some View {
        VStack(spacing: 0) {
            StatusBarView(viewModel: viewModel)
            board
        }
        .background(Theme.felt.ignoresSafeArea())
        .overlay {
            if viewModel.isWon {
                WinOverlayView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.isShowingSettings) {
            SettingsView(settings: viewModel.settings)
        }
    }

    private var board: some View {
        GeometryReader { geometry in
            let metrics = BoardMetrics(boardWidth: geometry.size.width)
            let tableauHeight = geometry.size.height - metrics.cardHeight - 2 * Self.rowSpacing
            VStack(spacing: Self.rowSpacing) {
                TopRowView(viewModel: viewModel, metrics: metrics, dropTarget: dropTarget)
                    .zIndex(viewModel.drag?.source.isTableau == false ? 1 : 0)
                HStack(alignment: .top, spacing: BoardMetrics.columnSpacing) {
                    ForEach(0 ..< GameState.tableauColumnCount, id: \.self) { index in
                        TableauColumnView(
                            viewModel: viewModel,
                            metrics: metrics,
                            index: index,
                            availableHeight: max(metrics.cardHeight, tableauHeight),
                            dropTarget: dropTarget
                        )
                        .zIndex(viewModel.drag?.source == .tableau(index) ? 1 : 0)
                    }
                }
            }
            .padding(.horizontal, BoardMetrics.horizontalPadding)
            .padding(.vertical, Self.rowSpacing)
        }
        .coordinateSpace(name: BoardMetrics.coordinateSpace)
        .onPreferenceChange(PileFramePreferenceKey.self) { pileFrames = $0 }
    }

    /// The pile under `point`, foundations and waste taking precedence over the tall tableau frames.
    private func dropTarget(at point: CGPoint) -> PileID? {
        let ordered = PileID.allFoundations + [.waste, .stock] + PileID.allTableau
        return ordered.first { pileFrames[$0]?.contains(point) == true }
    }
}

#Preview {
    GameView(viewModel: GameViewModel(store: InMemoryGameStore(), settings: GameSettings(defaults: .standard)))
}
