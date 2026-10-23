import SolitaireKit
import SwiftUI

/// VoiceOver text for the piles and the face-up cards on the board. Pile values stay
/// "<n> cards" because UI tests read them; the labels carry the rest.
enum BoardAccessibility {
    /// "Foundation 2, empty", "Foundation 2, six of hearts on top", "Column 3, 2 face down".
    static func label(for pile: PileID, in state: GameState) -> String {
        let cards = state.pile(pile)
        switch pile {
        case .stock:
            return cards.isEmpty ? "Stock, empty" : "Stock"
        case .waste:
            return cards.last.map { "Waste, \($0.name) on top" } ?? "Waste, empty"
        case let .foundation(index):
            let name = "Foundation \(index + 1)"
            return cards.last.map { "\(name), \($0.name) on top" } ?? "\(name), empty"
        case let .tableau(index):
            let name = "Column \(index + 1)"
            let hidden = cards.count { !$0.isFaceUp }
            if cards.isEmpty { return "\(name), empty" }
            return hidden == 0 ? name : "\(name), \(hidden) face down"
        }
    }

    /// What a double-tap on the stock does.
    static func stockHint(in state: GameState, canDraw: Bool) -> String {
        if canDraw { return state.stock.isEmpty ? "Double-tap to turn the waste over" : "Double-tap to draw" }
        return state.waste.isEmpty ? "" : "No passes left"
    }

    /// What a double-tap on a face-up card does, and where the custom actions are.
    static func cardHint(destinations: [PileID], from pile: PileID) -> String {
        if destinations.isEmpty { return "No legal move" }
        // A tap never takes a card off a foundation; only the actions do.
        if pile.isFoundation { return "Swipe up or down to choose where to move it" }
        return "Double-tap to move it to the best spot, or swipe up or down to choose"
    }

    /// The custom action that sends a card to `destination`.
    static func actionTitle(for destination: PileID) -> String {
        switch destination {
        case let .tableau(index): "Move to column \(index + 1)"
        default: "Move to foundation"
        }
    }
}

/// VoiceOver for a face-up card: a hint and one custom action per legal destination, so every
/// move can be made without dragging.
struct CardAccessibility: ViewModifier {
    let viewModel: GameViewModel
    let pile: PileID
    let index: Int

    func body(content: Content) -> some View {
        let destinations = viewModel.destinations(forCardAt: index, in: pile)
        content
            .accessibilityHint(BoardAccessibility.cardHint(destinations: destinations, from: pile))
            .accessibilityActions {
                ForEach(destinations, id: \.self) { destination in
                    Button(BoardAccessibility.actionTitle(for: destination)) {
                        viewModel.moveCards(from: pile, index: index, to: destination)
                    }
                }
            }
    }
}
