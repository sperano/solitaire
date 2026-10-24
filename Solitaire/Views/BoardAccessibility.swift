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
            return cards.isEmpty ? String(localized: "Stock, empty") : String(localized: "Stock")
        case .waste:
            return cards.last.map { String(localized: "Waste, \($0.spokenName) on top") }
                ?? String(localized: "Waste, empty")
        case let .foundation(index):
            let number = index + 1
            return cards.last.map { String(localized: "Foundation \(number), \($0.spokenName) on top") }
                ?? String(localized: "Foundation \(number), empty")
        case let .tableau(index):
            return columnLabel(number: index + 1, cards: cards)
        }
    }

    private static func columnLabel(number: Int, cards: [Card]) -> String {
        if cards.isEmpty { return String(localized: "Column \(number), empty") }
        let hidden = cards.count { !$0.isFaceUp }
        guard hidden > 0 else { return String(localized: "Column \(number)") }
        let faceDown = String(localized: "\(hidden) face down", comment: "Face-down cards in a column")
        return String(localized: "Column \(number), \(faceDown)", comment: "A column and its face-down cards")
    }

    /// What a double-tap on the stock does.
    static func stockHint(in state: GameState, canDraw: Bool) -> String {
        if canDraw {
            return state.stock.isEmpty
                ? String(localized: "Double-tap to turn the waste over")
                : String(localized: "Double-tap to draw")
        }
        return state.waste.isEmpty ? "" : String(localized: "No passes left", comment: "Vegas: the stock is spent")
    }

    /// What a double-tap on a face-up card does, and where the custom actions are.
    static func cardHint(destinations: [PileID], from pile: PileID) -> String {
        if destinations.isEmpty { return String(localized: "No legal move") }
        // A tap never takes a card off a foundation; only the actions do.
        if pile.isFoundation { return String(localized: "Swipe up or down to choose where to move it") }
        return String(localized: "Double-tap to move it to the best spot, or swipe up or down to choose")
    }

    /// The custom action that sends a card to `destination`.
    static func actionTitle(for destination: PileID) -> String {
        switch destination {
        case let .tableau(index): String(localized: "Move to column \(index + 1)")
        default: String(localized: "Move to foundation")
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
