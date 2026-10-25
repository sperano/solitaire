import CoreGraphics
import SolitaireKit

/// The order of the top row, and which way the waste fans. Right-handed: stock, waste, a gap,
/// then the foundations. Left-handed mirrors the stock and waste to the right, under the left
/// thumb, with the waste fanning left into the gap; the foundations keep their order.
struct TopRowLayout: Equatable {
    enum Slot: Hashable {
        case stock
        case waste
        case gap
        case foundation(Int)
    }

    let isLeftHanded: Bool

    var slots: [Slot] {
        let foundations = (0 ..< GameState.foundationCount).map(Slot.foundation)
        return isLeftHanded ? foundations + [.gap, .waste, .stock] : [.stock, .waste, .gap] + foundations
    }

    /// +1 when the waste fans right, towards the gap, −1 when it fans left.
    var wasteFanDirection: CGFloat { isLeftHanded ? -1 : 1 }
}
