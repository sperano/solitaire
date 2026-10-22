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

    init(defaults: UserDefaults) {
        self.defaults = defaults
        drawMode = DrawMode(rawValue: defaults.integer(forKey: Self.drawModeKey)) ?? Self.defaultDrawMode
        // `integer(forKey:)` reads a missing key as 0, which is `.none`, so check the key exists.
        let storedScoring = (defaults.object(forKey: Self.scoringModeKey) as? Int).flatMap(ScoringMode.init(rawValue:))
        scoringMode = storedScoring ?? Self.defaultScoringMode
        carryVegasBalance = defaults.bool(forKey: Self.carryVegasBalanceKey)
        vegasBalance = defaults.integer(forKey: Self.vegasBalanceKey)
    }

    /// The balance a new Vegas game starts from before the buy-in.
    var carriedVegasBalance: Int { carryVegasBalance ? vegasBalance : 0 }
}
