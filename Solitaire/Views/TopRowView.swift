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

    /// The waste is waiting but Vegas scoring allows no more passes through the stock.
    private var passesUsedUp: Bool { !viewModel.state.waste.isEmpty && !viewModel.canDraw }

    /// Recycle arrow while the waste can go back, a stop sign once Vegas passes run out.
    private var emptySymbol: String? {
        if viewModel.state.waste.isEmpty { return nil }
        return passesUsedUp ? "nosign" : "arrow.counterclockwise"
    }

    var body: some View {
        ZStack {
            EmptySlotView(metrics: metrics, symbol: emptySymbol, isHinted: viewModel.isHintedEmptySlot(.stock))
            if let top = cards.last {
                CardView(card: top, metrics: metrics, isHinted: viewModel.isHinted(.stock, index: cards.count - 1))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { viewModel.draw() }
        .reportFrame(as: .stock)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier(PileID.stock.accessibilityIdentifier)
        .accessibilityLabel(BoardAccessibility.label(for: .stock, in: viewModel.state))
        .accessibilityValue("\(cards.count) cards")
        .accessibilityHint(BoardAccessibility.stockHint(in: viewModel.state, canDraw: viewModel.canDraw))
        .accessibilityAction { viewModel.draw() }
        .accessibilityAddTraits(viewModel.isStockHinted ? [.isButton, .isSelected] : .isButton)
    }
}

struct WasteView: View {
    let viewModel: GameViewModel
    let metrics: BoardMetrics
    let dropTarget: (CGPoint) -> PileID?

    private var cards: [Card] { viewModel.state.waste }

    /// Only the last few cards are visible, fanned to the right, and only the top one moves.
    private var visible: [(index: Int, card: Card)] {
        cards.indices.suffix(BoardGeometry.visibleWasteCount(in: viewModel.state)).map { ($0, cards[$0]) }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            EmptySlotView(metrics: metrics)
            ForEach(Array(visible.enumerated()), id: \.element.card.id) { fanIndex, entry in
                let isTop = entry.index == cards.count - 1
                CardView(card: entry.card, metrics: metrics, isHinted: viewModel.isHinted(.waste, index: entry.index))
                    .offset(x: CGFloat(fanIndex) * metrics.wasteFanOffset)
                    .dragOffset(viewModel.drag, pile: .waste, index: entry.index, pileCount: cards.count)
                    .zIndex(Double(fanIndex))
                    .transition(.identity)
                    .allowsHitTesting(isTop)
                    // Only the top card can move; VoiceOver skips the rest of the fan.
                    .accessibilityHidden(!isTop)
                    .modifier(TopCardGestures(
                        enabled: isTop,
                        viewModel: viewModel,
                        pile: .waste,
                        pileCount: cards.count,
                        dropTarget: dropTarget
                    ))
            }
        }
        .frame(width: metrics.cardWidth, height: metrics.cardHeight, alignment: .leading)
        .reportFrame(as: .waste)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(PileID.waste.accessibilityIdentifier)
        .accessibilityLabel(BoardAccessibility.label(for: .waste, in: viewModel.state))
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
            EmptySlotView(metrics: metrics, symbol: Self.emptySymbol, isHinted: viewModel.isHintedEmptySlot(pile))
            ForEach(Array(cards.indices.suffix(Self.visibleCardCount)), id: \.self) { index in
                let isTop = index == cards.count - 1
                CardView(card: cards[index], metrics: metrics, isHinted: viewModel.isHinted(pile, index: index))
                    .dragOffset(viewModel.drag, pile: pile, index: index, pileCount: cards.count)
                    .transition(.identity)
                    .allowsHitTesting(isTop)
                    // Only drawn for drags; the pile's label already names the top card.
                    .accessibilityHidden(!isTop)
                    .modifier(TopCardGestures(
                        enabled: isTop,
                        viewModel: viewModel,
                        pile: pile,
                        pileCount: cards.count,
                        dropTarget: dropTarget
                    ))
            }
        }
        .reportFrame(as: pile)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(pile.accessibilityIdentifier)
        .accessibilityLabel(BoardAccessibility.label(for: pile, in: viewModel.state))
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
            content.cardGestures(
                viewModel: viewModel,
                pile: pile,
                index: pileCount - 1,
                pileCount: pileCount,
                dropTarget: dropTarget
            )
        } else {
            content
        }
    }
}
