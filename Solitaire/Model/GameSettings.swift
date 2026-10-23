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
    }

    /// The balance a new Vegas game starts from before the buy-in.
    var carriedVegasBalance: Int { carryVegasBalance ? vegasBalance : 0 }
}
