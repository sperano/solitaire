import SwiftUI

extension TableFelt {
    /// Each felt is dark enough for the white toolbar text and icons (at least 4.5:1).
    var color: Color {
        switch self {
        case .green: Theme.felt
        case .blue: Color(red: 0.07, green: 0.24, blue: 0.43)
        case .burgundy: Color(red: 0.42, green: 0.09, blue: 0.14)
        case .charcoal: Color(red: 0.19, green: 0.21, blue: 0.23)
        }
    }
}

extension CardBack {
    var color: Color {
        switch self {
        case .blue: Theme.cardBack
        case .red: Color(red: 0.70, green: 0.12, blue: 0.14)
        case .purple: Color(red: 0.38, green: 0.20, blue: 0.56)
        }
    }

    /// What is drawn inside the white frame every back has.
    var pattern: CardBackPattern {
        switch self {
        case .blue: .plain
        case .red: .lattice
        case .purple: .doubleFrame
        }
    }
}

enum CardBackPattern {
    case plain
    case lattice
    case doubleFrame
}
