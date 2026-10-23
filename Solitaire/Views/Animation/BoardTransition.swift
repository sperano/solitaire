import SolitaireKit

/// Where a card sits: its pile and its index in that pile, counted from the bottom.
struct CardSlot: Hashable {
    let pile: PileID
    let index: Int
}

/// A card that changed pile between two positions, with how it looked before and after.
struct CardFlight: Hashable, Identifiable {
    let before: Card
    let after: Card
    let from: CardSlot
    let to: CardSlot

    var id: String { after.id }
}

/// What changed between two positions of the same game, worked out from where every card is
/// rather than from the move, so a move, a draw, an undo and auto-complete all animate alike.
enum BoardTransition {
    private static let allPiles: [PileID] = [.stock, .waste] + PileID.allFoundations + PileID.allTableau

    /// Every card that changed pile, in board order: by destination pile, bottom card first.
    static func flights(from before: GameState, to after: GameState) -> [CardFlight] {
        let previous = Dictionary(uniqueKeysWithValues: cards(in: before).map { ($0.card.id, $0) })
        return cards(in: after).compactMap { slot, card in
            guard let old = previous[card.id], old.slot.pile != slot.pile else { return nil }
            return CardFlight(before: old.card, after: card, from: old.slot, to: slot)
        }
    }

    /// Every card on the board with its slot, pile by pile from the bottom card up.
    static func cards(in state: GameState) -> [(slot: CardSlot, card: Card)] {
        allPiles.flatMap { pile in
            state.pile(pile).enumerated().map { (CardSlot(pile: pile, index: $0.offset), $0.element) }
        }
    }
}
