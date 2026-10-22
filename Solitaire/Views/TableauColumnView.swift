import SolitaireKit
import SwiftUI

struct TableauColumnView: View {
    let viewModel: GameViewModel
    let metrics: BoardMetrics
    let index: Int
    let availableHeight: CGFloat
    let dropTarget: (CGPoint) -> PileID?

    private var pile: PileID { .tableau(index) }
    private var cards: [Card] { viewModel.state.tableau[index] }

    var body: some View {
        let offsets = metrics.columnOffsets(for: cards, availableHeight: availableHeight)
        ZStack(alignment: .top) {
            EmptySlotView(metrics: metrics, isHinted: viewModel.isHintedEmptySlot(pile))
            ForEach(Array(cards.enumerated()), id: \.element.id) { cardIndex, card in
                CardView(card: card, metrics: metrics, isHinted: viewModel.isHinted(pile, index: cardIndex))
                    .offset(y: offsets[cardIndex])
                    .dragOffset(viewModel.drag, pile: pile, index: cardIndex, pileCount: cards.count)
                    .zIndex(Double(cardIndex))
                    .transition(.opacity)
                    .modifier(FaceUpGestures(
                        enabled: card.isFaceUp,
                        viewModel: viewModel,
                        pile: pile,
                        index: cardIndex,
                        pileCount: cards.count,
                        dropTarget: dropTarget
                    ))
            }
        }
        .frame(width: metrics.cardWidth, height: availableHeight, alignment: .top)
        .contentShape(Rectangle())
        .reportFrame(as: pile)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(pile.accessibilityIdentifier)
        .accessibilityLabel("Column \(index + 1)")
        .accessibilityValue("\(cards.count) cards")
    }
}

private struct FaceUpGestures: ViewModifier {
    let enabled: Bool
    let viewModel: GameViewModel
    let pile: PileID
    let index: Int
    let pileCount: Int
    let dropTarget: (CGPoint) -> PileID?

    func body(content: Content) -> some View {
        if enabled {
            content.cardGestures(viewModel: viewModel, pile: pile, index: index, pileCount: pileCount, dropTarget: dropTarget)
        } else {
            content
        }
    }
}
