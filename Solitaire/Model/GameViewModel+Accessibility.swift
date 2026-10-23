import SolitaireKit

extension GameViewModel {
    /// Where the card at `index` of `pile`, with the run above it, can legally go: the first
    /// foundation that takes it, then every tableau column that does. Cards are never offered a
    /// move from one foundation to another. Empty while the board ignores input.
    func destinations(forCardAt index: Int, in pile: PileID) -> [PileID] {
        let count = state.pile(pile).count - index
        guard acceptsInput, count >= 1 else { return [] }
        let foundation = pile.isFoundation
            ? nil
            : PileID.allFoundations.first { game.canMove(count: count, from: pile, to: $0) }
        let columns = PileID.allTableau.filter { $0 != pile && game.canMove(count: count, from: pile, to: $0) }
        return (foundation.map { [$0] } ?? []) + columns
    }
}
