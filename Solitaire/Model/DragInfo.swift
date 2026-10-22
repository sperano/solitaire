import CoreGraphics
import SolitaireKit

/// The cards being dragged and how far they have moved from their pile.
struct DragInfo: Equatable {
    var source: PileID
    var count: Int
    var translation: CGSize

    /// True when the top `count` cards of `pile` are the ones being dragged.
    func covers(pile: PileID, index: Int, pileCount: Int) -> Bool {
        pile == source && index >= pileCount - count
    }
}
