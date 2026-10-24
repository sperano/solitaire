/// How a game is scored. Chosen when the game is dealt and kept for its whole life.
public enum ScoringMode: Int, Codable, CaseIterable, Sendable, Identifiable {
    case none = 0
    case standard = 1
    case vegas = 2

    public var id: Int { rawValue }
}
