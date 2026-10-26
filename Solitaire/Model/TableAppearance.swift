import Foundation

/// The design on the back of the cards (Settings → Cards). Its colours are in `TableColours`.
enum CardBack: String, CaseIterable, Identifiable {
    /// The original back: plain blue inside a white frame, as in the app icon.
    case blue
    /// A white diagonal lattice on red.
    case red
    /// Two nested white frames on purple.
    case purple

    static let defaultValue = CardBack.blue

    var id: Self { self }

    var title: String {
        switch self {
        case .blue: String(localized: "cardBack.blue", defaultValue: "Blue", comment: "Card back design")
        case .red: String(localized: "cardBack.red", defaultValue: "Red lattice", comment: "Card back design")
        case .purple: String(localized: "cardBack.purple", defaultValue: "Purple frames", comment: "Card back design")
        }
    }
}

/// The colour of the table under the cards (Settings → Cards). The launch screen stays green
/// whatever is chosen: it is a plain colour asset and cannot read the player's settings.
enum TableFelt: String, CaseIterable, Identifiable {
    case green
    case blue
    case burgundy
    case charcoal

    static let defaultValue = TableFelt.green

    var id: Self { self }

    var title: String {
        switch self {
        case .green: String(localized: "felt.green", defaultValue: "Green", comment: "Table colour")
        case .blue: String(localized: "felt.blue", defaultValue: "Blue", comment: "Table colour")
        case .burgundy: String(localized: "felt.burgundy", defaultValue: "Burgundy", comment: "Table colour")
        case .charcoal: String(localized: "felt.charcoal", defaultValue: "Charcoal", comment: "Table colour")
        }
    }
}
