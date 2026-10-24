import Foundation
import SolitaireKit

// The names players read and VoiceOver speaks for the engine's types. They live in the app, not
// in SolitaireKit, so they can come from the String Catalog. Ranks and suits use descriptive keys:
// English says "seven" both alone and in a sentence, French says "sept" and "le sept".

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

    /// The rank as the object of a sentence ("Move seven of hearts to…"); French adds the article.
    var nameInSentence: String {
        switch self {
        case .ace: String(localized: "rank.ace.inSentence", defaultValue: "ace", comment: "Rank, with article")
        case .two: String(localized: "rank.two.inSentence", defaultValue: "two", comment: "Rank, with article")
        case .three: String(localized: "rank.three.inSentence", defaultValue: "three", comment: "Rank, with article")
        case .four: String(localized: "rank.four.inSentence", defaultValue: "four", comment: "Rank, with article")
        case .five: String(localized: "rank.five.inSentence", defaultValue: "five", comment: "Rank, with article")
        case .six: String(localized: "rank.six.inSentence", defaultValue: "six", comment: "Rank, with article")
        case .seven: String(localized: "rank.seven.inSentence", defaultValue: "seven", comment: "Rank, with article")
        case .eight: String(localized: "rank.eight.inSentence", defaultValue: "eight", comment: "Rank, with article")
        case .nine: String(localized: "rank.nine.inSentence", defaultValue: "nine", comment: "Rank, with article")
        case .ten: String(localized: "rank.ten.inSentence", defaultValue: "ten", comment: "Rank, with article")
        case .jack: String(localized: "rank.jack.inSentence", defaultValue: "jack", comment: "Rank, with article")
        case .queen: String(localized: "rank.queen.inSentence", defaultValue: "queen", comment: "Rank, with article")
        case .king: String(localized: "rank.king.inSentence", defaultValue: "king", comment: "Rank, with article")
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
    var spokenName: String { Self.name(rank: rank.spokenName, suit: suit.spokenName) }

    /// The card as the object of a sentence: "seven of hearts", in French "le sept de cœur".
    var nameInSentence: String { Self.name(rank: rank.nameInSentence, suit: suit.spokenName) }

    private static func name(rank: String, suit: String) -> String {
        String(localized: "\(rank) of \(suit)", comment: "A card: its rank, then its suit")
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
}
