import SolitaireKit
import SwiftUI

struct GameView: View {
    /// The whole game screen, where the win cascade finds the foundations.
    private static let screenSpace = "game"
    private static let noHintPadding: CGFloat = 12

    @Bindable var viewModel: GameViewModel
    @State private var pileFrames: [PileID: CGRect] = [:]
    @State private var boardSize: CGSize = .zero
    /// Where the board starts on the game screen, below the status bar.
    @State private var boardOrigin: CGPoint = .zero
    @State private var flights: [ActiveFlight] = []
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private var cardStyle: CardStyle {
        let settings = viewModel.settings
        return CardStyle(
            isFourColour: settings.fourColorDeck, isHighContrast: contrast == .increased,
            isLargePrint: settings.largePrint, back: settings.cardBack
        )
    }

    private var topRow: TopRowLayout { TopRowLayout(isLeftHanded: viewModel.settings.leftHanded) }

    var body: some View {
        VStack(spacing: 0) {
            StatusBarView(viewModel: viewModel)
            board
        }
        .coordinateSpace(name: Self.screenSpace)
        .environment(\.cardStyle, cardStyle)
        .onChange(of: BoardSnapshot(gameID: viewModel.gameID, state: viewModel.state)) { old, new in
            startFlights(from: old, to: new)
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            viewModel.setAppActive(phase == .active)
        }
        .background(viewModel.settings.felt.color.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            if viewModel.isDealing {
                dealingBanner
            } else if viewModel.hint == .noUsefulMove {
                noHintBanner
            }
        }
        .overlay {
            if viewModel.isWon {
                WinOverlayView(viewModel: viewModel, celebration: cascade)
            }
        }
        .sheet(isPresented: $viewModel.isShowingSettings, onDismiss: viewModel.settingsDismissed) {
            SettingsView(
                settings: viewModel.settings, statistics: viewModel.statistics,
                dealNumber: viewModel.dealNumber, drawMode: viewModel.state.drawMode,
                isGameStarted: viewModel.moveCount > 0 && !viewModel.isWon, playDeal: viewModel.playDeal
            )
        }
    }

    private var board: some View {
        GeometryReader { geometry in
            let metrics = BoardMetrics(boardSize: geometry.size)
            let tableauHeight = metrics.tableauHeight(boardHeight: geometry.size.height)
            VStack(spacing: BoardMetrics.rowSpacing) {
                TopRowView(viewModel: viewModel, metrics: metrics, layout: topRow, dropTarget: dropTarget)
                    .zIndex(viewModel.drag?.source.isTableau == false ? 1 : 0)
                HStack(alignment: .top, spacing: BoardMetrics.columnSpacing) {
                    ForEach(0 ..< GameState.tableauColumnCount, id: \.self) { index in
                        TableauColumnView(
                            viewModel: viewModel,
                            metrics: metrics,
                            index: index,
                            availableHeight: tableauHeight,
                            dropTarget: dropTarget
                        )
                        .zIndex(viewModel.drag?.source == .tableau(index) ? 1 : 0)
                    }
                }
            }
            .padding(.horizontal, BoardMetrics.horizontalPadding)
            .padding(.vertical, BoardMetrics.rowSpacing)
            // Centred when the height, not the width, sets the card size (landscape, short windows).
            .frame(maxWidth: .infinity)
            .environment(\.cardsInFlight, Set(flights.map(\.cardID)))
            .overlay(alignment: .topLeading) {
                FlightLayer(flights: flights, metrics: metrics) { landed in
                    withoutAnimation { flights.removeAll { $0.id == landed.id } }
                }
            }
            .onAppear { measure(geometry) }
            .onChange(of: geometry.frame(in: .named(Self.screenSpace))) { measure(geometry) }
        }
        .coordinateSpace(name: BoardMetrics.coordinateSpace)
        .onPreferenceChange(PileFramePreferenceKey.self) { pileFrames = $0 }
    }

    /// Shown while a winnable deal is searched for; the board behind it ignores input.
    private var dealingBanner: some View {
        ProgressView {
            Text("Dealing…").font(.headline)
        }
        .progressViewStyle(.circular)
        .padding(Self.noHintPadding)
        .background(.thinMaterial, in: Capsule())
        .padding(Self.noHintPadding)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("dealingLabel")
    }

    private var noHintBanner: some View {
        Text(HintAnnouncement.noUsefulMove)
            .font(.headline)
            .padding(Self.noHintPadding)
            .background(.thinMaterial, in: Capsule())
            .padding(Self.noHintPadding)
            .accessibilityIdentifier("noHintLabel")
    }

    /// Flies the cards a move, draw, undo or auto-complete step carried to their new pile, or deals
    /// a new game from the stock. Nothing flies under Reduce Motion.
    private func startFlights(from old: BoardSnapshot, to new: BoardSnapshot) {
        let planner = FlightPlanner(geometry: BoardGeometry(
            metrics: BoardMetrics(boardSize: boardSize),
            pileFrames: pileFrames,
            topRow: topRow
        ))
        // Hiding the landed cards must take effect in the frame they appear, never fade.
        withoutAnimation {
            if reduceMotion {
                flights = []
            } else if old.gameID != new.gameID {
                flights = planner.deal(new.state)
            } else {
                let started = planner.moves(from: old.state, to: new.state, drop: viewModel.lastDrop)
                let restarted = Set(started.map(\.cardID))
                flights = flights.filter { !restarted.contains($0.cardID) } + started
            }
        }
    }

    private func withoutAnimation(_ change: () -> Void) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction, change)
    }

    private func measure(_ geometry: GeometryProxy) {
        boardSize = geometry.size
        boardOrigin = geometry.frame(in: .named(Self.screenSpace)).origin
    }

    /// The win cascade, launched from where the foundations are on the screen.
    private func cascade(in size: CGSize) -> WinCascadeView? {
        guard !reduceMotion else { return nil }
        let foundations = PileID.allFoundations.compactMap { pile -> (cards: [Card], frame: CGRect)? in
            pileFrames[pile].map { (viewModel.state.pile(pile), $0.offsetBy(dx: boardOrigin.x, dy: boardOrigin.y)) }
        }
        // Starts once the winning card has landed, so it isn't on screen twice.
        return WinCascadeView(
            foundations: foundations, bounds: CGRect(origin: .zero, size: size),
            metrics: BoardMetrics(boardSize: boardSize), delay: FlightPlanner.moveSeconds
        )
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

/// What the board shows, compared before and after a change to choose its animation.
private struct BoardSnapshot: Equatable {
    let gameID: UInt64
    let state: GameState
}
