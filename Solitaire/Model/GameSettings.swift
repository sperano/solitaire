import Foundation
import SolitaireKit

/// User preferences, backed by `UserDefaults` so tests can pass their own suite.
@MainActor
@Observable
final class GameSettings {
    static let drawModeKey = "drawMode"
    static let defaultDrawMode = DrawMode.one

    private let defaults: UserDefaults

    var drawMode: DrawMode {
        didSet { defaults.set(drawMode.rawValue, forKey: Self.drawModeKey) }
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        let stored = defaults.integer(forKey: Self.drawModeKey)
        drawMode = DrawMode(rawValue: stored) ?? Self.defaultDrawMode
    }
}
