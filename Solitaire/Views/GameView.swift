import SolitaireKit
import SwiftUI

struct GameView: View {
    private static let rowSpacing: CGFloat = 12
    private static let verticalGapCount: CGFloat = 3
    /// Each auto-complete step fades its card across, finishing before the next step starts.
    private static let autoCompleteAnimation = Animation.easeInOut(
        duration: GameViewModel.autoCompleteStepSeconds * autoCompleteAnimationShare
    )
    private static let autoCompleteAnimationShare = 0.8
    private static let noHintPadding: CGFloat = 12

    @Bindable var viewModel: GameViewModel
    @State private var pileFrames: [PileID: CGRect] = [:]
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var cardStyle: CardStyle {
        CardStyle(isFourColour: viewModel.settings.fourColorDeck, isHighContrast: contrast == .increased)
    }

    var body: some View {
        VStack(spacing: 0) {
            StatusBarView(viewModel: viewModel)
            board
        }
        .environment(\.cardStyle, cardStyle)
        .background(Theme.felt.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            if viewModel.hint == .noUsefulMove {
                noHintBanner
            }
        }
        .overlay {
            if viewModel.isWon {
                WinOverlayView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.isShowingSettings, onDismiss: viewModel.settingsDismissed) {
            SettingsView(settings: viewModel.settings, statistics: viewModel.statistics)
        }
    }

    private var board: some View {
        GeometryReader { geometry in
            let metrics = BoardMetrics(boardWidth: geometry.size.width)
            // Vertical padding above and below, plus the gap between the two rows.
            let tableauHeight = geometry.size.height - metrics.cardHeight - Self.verticalGapCount * Self.rowSpacing
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
        .transaction(value: viewModel.moveCount) { transaction in
            if viewModel.isAutoCompleting {
                transaction.animation = Motion.animation(Self.autoCompleteAnimation, reduceMotion: reduceMotion)
            }
        }
        .coordinateSpace(name: BoardMetrics.coordinateSpace)
        .onPreferenceChange(PileFramePreferenceKey.self) { pileFrames = $0 }
    }

    private var noHintBanner: some View {
        Text(HintAnnouncement.noUsefulMove)
            .font(.headline)
            .padding(Self.noHintPadding)
            .background(.thinMaterial, in: Capsule())
            .padding(Self.noHintPadding)
            .accessibilityIdentifier("noHintLabel")
    }

    /// The pile under `point`, foundations and waste taking precedence over the tall tableau frames.
    private func dropTarget(at point: CGPoint) -> PileID? {
        let ordered = PileID.allFoundations + [.waste, .stock] + PileID.allTableau
        return ordered.first { pileFrames[$0]?.contains(point) == true }
    }
}

#Preview {
    GameView(viewModel: GameViewModel(
        store: InMemoryGameStore(),
        settings: GameSettings(defaults: .standard),
        statistics: StatisticsModel(store: InMemoryStatisticsStore())
    ))
}
