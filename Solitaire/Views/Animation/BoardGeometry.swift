import SolitaireKit
import SwiftUI

/// Where each card is drawn on the board, in the board's coordinate space, so a flying card can
/// start and end exactly where the pile views draw it.
struct BoardGeometry {
    let metrics: BoardMetrics
    /// Pile frames as the pile views report them (see `PileFramePreferenceKey`).
    let pileFrames: [PileID: CGRect]
    /// Which way the waste fans, as `WasteView` draws it.
    var topRow = TopRowLayout(isLeftHanded: false)

    /// The card's frame in `state`, or nil before the pile has been laid out.
    func frame(of slot: CardSlot, in state: GameState) -> CGRect? {
        guard let pileFrame = pileFrames[slot.pile] else { return nil }
        return CGRect(origin: origin(of: slot, in: state, pileFrame: pileFrame), size: metrics.cardSize)
    }

    private func origin(of slot: CardSlot, in state: GameState, pileFrame: CGRect) -> CGPoint {
        let cards = state.pile(slot.pile)
        switch slot.pile {
        case .stock, .foundation:
            return pileFrame.origin
        case .waste:
            let fanIndex = max(0, slot.index - (cards.count - Self.visibleWasteCount(in: state)))
            let fan = topRow.wasteFanDirection * CGFloat(fanIndex) * metrics.wasteFanOffset
            return CGPoint(x: pileFrame.minX + fan, y: pileFrame.minY)
        case .tableau:
            let offsets = metrics.columnOffsets(for: cards, availableHeight: pileFrame.height)
            let offset = offsets.indices.contains(slot.index) ? offsets[slot.index] : 0
            return CGPoint(x: pileFrame.minX, y: pileFrame.minY + offset)
        }
    }

    /// The waste shows its top cards fanned, as many as one draw turns over (see `WasteView`).
    static func visibleWasteCount(in state: GameState) -> Int {
        min(state.waste.count, state.drawMode.cardsPerDraw)
    }
}
