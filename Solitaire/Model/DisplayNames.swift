import Foundation
import SolitaireKit

// The names players read and VoiceOver speaks for the engine's types. They live in the app, not
// in SolitaireKit, so they can come from the String Catalog. Ranks, suits and cards in a sentence
// use descriptive keys: English says "seven of hearts" both alone and in a sentence, French says
// "sept de cœur" and "le sept de cœur", German "Herz-Sieben" and "die Herz-Sieben".

extension Rank {
    /// The rank alone, lower case: "seven" ("Waste, seven of hearts on top").
    var spokenName: String {
        switch self {
        case .ace: String(localized: "rank.ace", defaultValue: "ace", comment: "Card rank, alone")
        case .two: String(localized: "rank.two", defaultValue: "two", comment: "Card rank, alone")
        case .three: String(localized: "rank.three", defaultValue: "three", comment: "Card rank, alone")
        case .four: String(localized: "rank.four", defaultValue: "four", comment: "Card rank, alone")
        case .five: String(localized: "rank.five", defaultValue: "five", comment: "Card rank, alone")
        case .six: String(localized: "rank.six", defaultValue: "six", comment: "Card rank, alone")
        case .seven: String(localized: "rank.seven", defaultValue: "seven", comment: "Card rank, alone")
        case .eight: String(localized: "rank.eight", defaultValue: "eight", comment: "Card rank, alone")
        case .nine: String(localized: "rank.nine", defaultValue: "nine", comment: "Card rank, alone")
        case .ten: String(localized: "rank.ten", defaultValue: "ten", comment: "Card rank, alone")
        case .jack: String(localized: "rank.jack", defaultValue: "jack", comment: "Card rank, alone")
        case .queen: String(localized: "rank.queen", defaultValue: "queen", comment: "Card rank, alone")
        case .king: String(localized: "rank.king", defaultValue: "king", comment: "Card rank, alone")
        }
    }
}

extension Suit {
    /// The suit as it follows a rank: "hearts" in "seven of hearts".
    var spokenName: String {
        switch self {
        case .clubs: String(localized: "suit.clubs", defaultValue: "clubs", comment: "Card suit")
        case .diamonds: String(localized: "suit.diamonds", defaultValue: "diamonds", comment: "Card suit")
        case .hearts: String(localized: "suit.hearts", defaultValue: "hearts", comment: "Card suit")
        case .spades: String(localized: "suit.spades", defaultValue: "spades", comment: "Card suit")
        }
    }
}

extension Card {
    /// "seven of hearts", lower case, for a label that names the card.
    var spokenName: String {
        String(localized: "\(rank.spokenName) of \(suit.spokenName)", comment: "A card: its rank, then its suit")
    }

    /// The card as the object of a hint ("Move seven of hearts to…"): in French "le sept de cœur",
    /// in German the accusative "den Herz-Buben". The article agrees with the rank and German puts
    /// it before the suit, so each rank has its own key, with the suit as an argument.
    var nameInSentence: String {
        let suit = suit.spokenName
        return switch rank {
        case .ace:
            String(localized: "card.ace.inSentence", defaultValue: "ace of \(suit)", comment: "Card, with article")
        case .two:
            String(localized: "card.two.inSentence", defaultValue: "two of \(suit)", comment: "Card, with article")
        case .three:
            String(localized: "card.three.inSentence", defaultValue: "three of \(suit)", comment: "Card, with article")
        case .four:
            String(localized: "card.four.inSentence", defaultValue: "four of \(suit)", comment: "Card, with article")
        case .five:
            String(localized: "card.five.inSentence", defaultValue: "five of \(suit)", comment: "Card, with article")
        case .six:
            String(localized: "card.six.inSentence", defaultValue: "six of \(suit)", comment: "Card, with article")
        case .seven:
            String(localized: "card.seven.inSentence", defaultValue: "seven of \(suit)", comment: "Card, with article")
        case .eight:
            String(localized: "card.eight.inSentence", defaultValue: "eight of \(suit)", comment: "Card, with article")
        case .nine:
            String(localized: "card.nine.inSentence", defaultValue: "nine of \(suit)", comment: "Card, with article")
        case .ten:
            String(localized: "card.ten.inSentence", defaultValue: "ten of \(suit)", comment: "Card, with article")
        case .jack:
            String(localized: "card.jack.inSentence", defaultValue: "jack of \(suit)", comment: "Card, with article")
        case .queen:
            String(localized: "card.queen.inSentence", defaultValue: "queen of \(suit)", comment: "Card, with article")
        case .king:
            String(localized: "card.king.inSentence", defaultValue: "king of \(suit)", comment: "Card, with article")
        }
    }
}

extension DrawMode {
    /// "Draw 3", on the picker and in sentences about the mode.
    var title: String {
        String(localized: "Draw \(cardsPerDraw)", comment: "Draw mode: how many cards a draw turns over")
    }
}

extension ScoringMode {
    var title: String {
        switch self {
        case .none: String(localized: "None", comment: "Scoring mode: no score")
        case .standard: String(localized: "Standard", comment: "Scoring mode")
        case .vegas: String(localized: "Vegas", comment: "Scoring mode")
        }
    }
}

/// Counts that read as a phrase, plural forms from the String Catalog.
enum CountPhrase {
    /// "12 moves", "1 move": the status bar's spoken label and the win summary.
    static func moves(_ count: Int) -> String {
        String(localized: "\(count) moves", comment: "Number of moves made in the game")
    }

    /// "12 points", "1 point": a standard score on the best-scores table.
    static func points(_ count: Int) -> String {
        String(localized: "\(count) points", comment: "A standard score")
    }
}
