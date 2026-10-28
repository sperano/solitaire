import Foundation
import SolitaireKit

/// User preferences, backed by `UserDefaults` so tests can pass their own suite.
@MainActor
@Observable
final class GameSettings {
    static let drawModeKey = "drawMode"
    static let scoringModeKey = "scoringMode"
    static let carryVegasBalanceKey = "carryVegasBalance"
    static let vegasBalanceKey = "vegasBalance"
    static let autoFinishKey = "autoFinish"
    static let fourColorDeckKey = "fourColorDeck"
    static let hapticsKey = "haptics"
    static let soundEffectsKey = "soundEffects"
    static let winnableDealsOnlyKey = "winnableDealsOnly"
    static let timedKey = "timed"
    static let leftHandedKey = "leftHanded"
    static let largePrintKey = "largePrint"
    static let cardBackKey = "cardBack"
    static let feltKey = "felt"
    static let defaultDrawMode = DrawMode.one
    static let defaultScoringMode = ScoringMode.standard

    private let defaults: UserDefaults

    var drawMode: DrawMode {
        didSet { defaults.set(drawMode.rawValue, forKey: Self.drawModeKey) }
    }

    var scoringMode: ScoringMode {
        didSet { defaults.set(scoringMode.rawValue, forKey: Self.scoringModeKey) }
    }

    /// Start each Vegas game from the balance the previous one ended with. Turning it off clears the balance.
    var carryVegasBalance: Bool {
        didSet {
            defaults.set(carryVegasBalance, forKey: Self.carryVegasBalanceKey)
            if !carryVegasBalance { vegasBalance = 0 }
        }
    }

    /// The Vegas balance the last finished or abandoned game left, used when the balance is carried.
    var vegasBalance: Int {
        didSet { defaults.set(vegasBalance, forKey: Self.vegasBalanceKey) }
    }

    /// Finish the game without asking once every remaining card can go to the foundations.
    var autoFinish: Bool {
        didSet { defaults.set(autoFinish, forKey: Self.autoFinishKey) }
    }

    /// Diamonds blue and clubs green, so every suit has its own colour.
    var fourColorDeck: Bool {
        didSet { defaults.set(fourColorDeck, forKey: Self.fourColorDeckKey) }
    }

    /// A tap of the Taptic Engine on moves, refused moves and the win. On unless turned off.
    var haptics: Bool {
        didSet { defaults.set(haptics, forKey: Self.hapticsKey) }
    }

    /// Short sounds for a draw, a card put down or turned over, an undo and the win. Off unless turned on.
    var soundEffects: Bool {
        didSet { defaults.set(soundEffects, forKey: Self.soundEffectsKey) }
    }

    /// Deal only games the solver can win; a deal number asked for is dealt as it is.
    var winnableDealsOnly: Bool {
        didSet { defaults.set(winnableDealsOnly, forKey: Self.winnableDealsOnlyKey) }
    }

    /// Games are timed: the clock shows and runs, a standard win earns its time bonus and a win
    /// can set a best time. Off, the game is untimed and none of that happens. On unless turned off.
    var timed: Bool {
        didSet { defaults.set(timed, forKey: Self.timedKey) }
    }

    /// Stock and waste on the right of the top row, under the left thumb. Takes effect at once.
    var leftHanded: Bool {
        didSet { defaults.set(leftHanded, forKey: Self.leftHandedKey) }
    }

    /// Bigger ranks and suits on the card faces.
    var largePrint: Bool {
        didSet { defaults.set(largePrint, forKey: Self.largePrintKey) }
    }

    var cardBack: CardBack {
        didSet { defaults.set(cardBack.rawValue, forKey: Self.cardBackKey) }
    }

    /// The table's colour.
    var felt: TableFelt {
        didSet { defaults.set(felt.rawValue, forKey: Self.feltKey) }
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        drawMode = DrawMode(rawValue: defaults.integer(forKey: Self.drawModeKey)) ?? Self.defaultDrawMode
        // `integer(forKey:)` reads a missing key as 0, which is `.none`, so check the key exists.
        let storedScoring = (defaults.object(forKey: Self.scoringModeKey) as? Int).flatMap(ScoringMode.init(rawValue:))
        scoringMode = storedScoring ?? Self.defaultScoringMode
        carryVegasBalance = defaults.bool(forKey: Self.carryVegasBalanceKey)
        vegasBalance = defaults.integer(forKey: Self.vegasBalanceKey)
        autoFinish = defaults.bool(forKey: Self.autoFinishKey)
        fourColorDeck = defaults.bool(forKey: Self.fourColorDeckKey)
        haptics = defaults.object(forKey: Self.hapticsKey) as? Bool ?? true
        soundEffects = defaults.bool(forKey: Self.soundEffectsKey)
        winnableDealsOnly = defaults.bool(forKey: Self.winnableDealsOnlyKey)
        timed = defaults.object(forKey: Self.timedKey) as? Bool ?? true
        leftHanded = defaults.bool(forKey: Self.leftHandedKey)
        largePrint = defaults.bool(forKey: Self.largePrintKey)
        cardBack = defaults.string(forKey: Self.cardBackKey).flatMap(CardBack.init(rawValue:)) ?? .defaultValue
        felt = defaults.string(forKey: Self.feltKey).flatMap(TableFelt.init(rawValue:)) ?? .defaultValue
    }

    /// The balance a new Vegas game starts from before the buy-in.
    var carriedVegasBalance: Int { carryVegasBalance ? vegasBalance : 0 }
}
