import SolitaireKit
import SwiftUI

/// Turns a change on the board into card flights: the cards that changed pile, or a whole new deal.
struct FlightPlanner {
    static let moveSeconds = 0.25
    static let dealSeconds = 0.3
    /// Between two cards of the deal, so they leave the stock one after the other.
    static let dealStaggerSeconds = 0.03

    let geometry: BoardGeometry

    /// A flight for every card that changed pile. Cards that were dropped start where the
    /// finger let them go rather than back in their pile.
    func moves(from before: GameState, to after: GameState, drop: DragInfo?) -> [ActiveFlight] {
        BoardTransition.flights(from: before, to: after).compactMap { flight in
            guard var from = geometry.frame(of: flight.from, in: before),
                  let to = geometry.frame(of: flight.to, in: after) else { return nil }
            let pileCount = before.pile(flight.from.pile).count
            if let drop, drop.covers(pile: flight.from.pile, index: flight.from.index, pileCount: pileCount) {
                from = from.offsetBy(dx: drop.translation.width, dy: drop.translation.height)
            }
            return ActiveFlight(
                before: flight.before, after: flight.after, from: from, to: to,
                delay: 0, duration: Self.moveSeconds
            )
        }
    }

    /// Every tableau card leaving the stock face down in the order a dealer deals them, row by
    /// row, and turning over as it lands if it is dealt face up.
    func deal(_ state: GameState) -> [ActiveFlight] {
        guard let stock = geometry.frame(of: CardSlot(pile: .stock, index: 0), in: state) else { return [] }
        let order = (0 ..< GameState.tableauColumnCount).flatMap { row in
            (row ..< GameState.tableauColumnCount).map { CardSlot(pile: .tableau($0), index: row) }
        }
        return order.enumerated().compactMap { position, slot in
            guard let to = geometry.frame(of: slot, in: state) else { return nil }
            let card = state.pile(slot.pile)[slot.index]
            return ActiveFlight(
                before: card.faceDown(), after: card, from: stock, to: to,
                delay: Double(position) * Self.dealStaggerSeconds, duration: Self.dealSeconds
            )
        }
    }
}
