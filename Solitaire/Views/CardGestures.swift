import SolitaireKit
import SwiftUI

/// Tap to auto-move, drag to move explicitly. Applied to the face-up cards of a pile.
struct CardGestures: ViewModifier {
    private static let dragMinimumDistance: CGFloat = 6
    private static let snapBackDuration: TimeInterval = 0.15

    let viewModel: GameViewModel
    let pile: PileID
    let index: Int
    let pileCount: Int
    let dropTarget: (CGPoint) -> PileID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var count: Int { pileCount - index }

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                viewModel.tapCard(in: pile, index: index)
            }
            .modifier(CardAccessibility(viewModel: viewModel, pile: pile, index: index))
            .gesture(
                DragGesture(minimumDistance: Self.dragMinimumDistance, coordinateSpace: .named(BoardMetrics.coordinateSpace))
                    .onChanged { value in
                        viewModel.drag = DragInfo(source: pile, count: count, translation: value.translation)
                    }
                    .onEnded { value in
                        let target = dropTarget(value.location)
                        withAnimation(Motion.animation(.easeOut(duration: Self.snapBackDuration), reduceMotion: reduceMotion)) {
                            _ = viewModel.drop(on: target == pile ? nil : target)
                        }
                    }
            )
    }
}

extension View {
    func cardGestures(
        viewModel: GameViewModel,
        pile: PileID,
        index: Int,
        pileCount: Int,
        dropTarget: @escaping (CGPoint) -> PileID?
    ) -> some View {
        modifier(CardGestures(viewModel: viewModel, pile: pile, index: index, pileCount: pileCount, dropTarget: dropTarget))
    }

    /// Shift the card by the drag translation when it is part of the dragged run.
    func dragOffset(_ drag: DragInfo?, pile: PileID, index: Int, pileCount: Int) -> some View {
        let covered = drag?.covers(pile: pile, index: index, pileCount: pileCount) ?? false
        return offset(covered ? drag!.translation : .zero)
    }
}
