import SolitaireKit
import SwiftUI

/// Stock, waste, a gap, then the four foundations.
struct TopRowView: View {
    let viewModel: GameViewModel
    let metrics: BoardMetrics
    let dropTarget: (CGPoint) -> PileID?

    var body: some View {
        HStack(spacing: BoardMetrics.columnSpacing) {
            StockView(viewModel: viewModel, metrics: metrics)
            WasteView(viewModel: viewModel, metrics: metrics, dropTarget: dropTarget)
            Color.clear.frame(width: metrics.cardWidth, height: metrics.cardHeight)
            ForEach(0 ..< GameState.foundationCount, id: \.self) { index in
                FoundationView(viewModel: viewModel, metrics: metrics, index: index, dropTarget: dropTarget)
            }
        }
    }
}

struct StockView: View {
    let viewModel: GameViewModel
    let metrics: BoardMetrics

    private var cards: [Card] { viewModel.state.stock }

    var body: some View {
        ZStack {
            EmptySlotView(metrics: metrics, symbol: viewModel.state.waste.isEmpty ? nil : "arrow.counterclockwise")
            if let top = cards.last {
                CardView(card: top, metrics: metrics)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { viewModel.draw() }
        .reportFrame(as: .stock)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier(PileID.stock.accessibilityIdentifier)
        .accessibilityLabel("Stock")
        .accessibilityValue("\(cards.count) cards")
        .accessibilityAddTraits(.isButton)
    }
}

struct WasteView: View {
    let viewModel: GameViewModel
    let metrics: BoardMetrics
    let dropTarget: (CGPoint) -> PileID?

    private var cards: [Card] { viewModel.state.waste }

    /// Only the last few cards are visible, fanned to the right, and only the top one moves.
    private var visible: [(index: Int, card: Card)] {
        let shown = min(cards.count, viewModel.state.drawMode.cardsPerDraw)
        return cards.indices.suffix(shown).map { ($0, cards[$0]) }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            EmptySlotView(metrics: metrics)
            ForEach(Array(visible.enumerated()), id: \.element.card.id) { fanIndex, entry in
                let isTop = entry.index == cards.count - 1
                CardView(card: entry.card, metrics: metrics)
                    .offset(x: CGFloat(fanIndex) * metrics.wasteFanOffset)
                    .dragOffset(viewModel.drag, pile: .waste, index: entry.index, pileCount: cards.count)
                    .zIndex(Double(fanIndex))
                    .allowsHitTesting(isTop)
                    .modifier(TopCardGestures(enabled: isTop, viewModel: viewModel, pile: .waste, pileCount: cards.count, dropTarget: dropTarget))
            }
        }
        .frame(width: metrics.cardWidth, height: metrics.cardHeight, alignment: .leading)
        .reportFrame(as: .waste)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(PileID.waste.accessibilityIdentifier)
        .accessibilityLabel("Waste")
        .accessibilityValue("\(cards.count) cards")
    }
}

struct FoundationView: View {
    /// The card under the top one stays visible while the top card is dragged away.
    private static let visibleCardCount = 2
    /// Any ace can start any foundation, so the empty slot shows a generic marker, not a suit.
    private static let emptySymbol = "a.square"

    let viewModel: GameViewModel
    let metrics: BoardMetrics
    let index: Int
    let dropTarget: (CGPoint) -> PileID?

    private var pile: PileID { .foundation(index) }
    private var cards: [Card] { viewModel.state.foundations[index] }

    var body: some View {
        ZStack {
            EmptySlotView(metrics: metrics, symbol: Self.emptySymbol)
            ForEach(Array(cards.indices.suffix(Self.visibleCardCount)), id: \.self) { index in
                let isTop = index == cards.count - 1
                CardView(card: cards[index], metrics: metrics)
                    .dragOffset(viewModel.drag, pile: pile, index: index, pileCount: cards.count)
                    .allowsHitTesting(isTop)
                    .modifier(TopCardGestures(enabled: isTop, viewModel: viewModel, pile: pile, pileCount: cards.count, dropTarget: dropTarget))
            }
        }
        .reportFrame(as: pile)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(pile.accessibilityIdentifier)
        .accessibilityLabel("Foundation \(index + 1)")
        .accessibilityValue("\(cards.count) cards")
    }
}

/// Gestures for the single movable card of the waste or a foundation.
private struct TopCardGestures: ViewModifier {
    let enabled: Bool
    let viewModel: GameViewModel
    let pile: PileID
    let pileCount: Int
    let dropTarget: (CGPoint) -> PileID?

    func body(content: Content) -> some View {
        if enabled {
            content.cardGestures(viewModel: viewModel, pile: pile, index: pileCount - 1, pileCount: pileCount, dropTarget: dropTarget)
        } else {
            content
        }
    }
}
