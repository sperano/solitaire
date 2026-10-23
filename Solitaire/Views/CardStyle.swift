import SolitaireKit
import SwiftUI

/// How cards and empty slots are drawn: the standard look, a high-contrast one when the system's
/// Increase Contrast is on, and a four-colour deck for players who tell suits apart by colour.
struct CardStyle: Equatable {
    private static let standardBorderWidth: CGFloat = 1
    private static let highContrastBorderWidth: CGFloat = 2
    private static let standardSlotStrokeWidth: CGFloat = 1.5
    private static let highContrastSlotStrokeWidth: CGFloat = 2.5

    let isFourColour: Bool
    let isHighContrast: Bool

    static let standard = CardStyle(isFourColour: false, isHighContrast: false)

    var border: Color { isHighContrast ? Theme.highContrastBorder : Theme.cardBorder }
    var borderWidth: CGFloat { isHighContrast ? Self.highContrastBorderWidth : Self.standardBorderWidth }
    var slotStroke: Color { isHighContrast ? Theme.highContrastSlotStroke : Theme.slotStroke }
    var slotStrokeWidth: CGFloat { isHighContrast ? Self.highContrastSlotStrokeWidth : Self.standardSlotStrokeWidth }
    var backInner: Color { isHighContrast ? Theme.highContrastBackInner : Theme.cardBackInner }

    /// The colour of the rank and suit symbols on a card's face: red and black, or with the
    /// four-colour deck black spades, red hearts, blue diamonds and green clubs.
    func ink(for suit: Suit) -> Color {
        switch (suit, isFourColour) {
        case (.spades, _), (.clubs, false): Theme.black
        case (.hearts, _), (.diamonds, false): isHighContrast ? Theme.highContrastRed : Theme.red
        case (.diamonds, true): isHighContrast ? Theme.highContrastBlue : Theme.blue
        case (.clubs, true): isHighContrast ? Theme.highContrastGreen : Theme.green
        }
    }
}

extension EnvironmentValues {
    @Entry var cardStyle = CardStyle.standard
}
