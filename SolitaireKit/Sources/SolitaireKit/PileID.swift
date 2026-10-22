/// Identifies one of the thirteen piles on a Klondike board.
public enum PileID: Hashable, Codable, Sendable {
    case stock
    case waste
    case foundation(Int)
    case tableau(Int)

    public static let allFoundations: [PileID] = (0 ..< GameState.foundationCount).map { .foundation($0) }
    public static let allTableau: [PileID] = (0 ..< GameState.tableauColumnCount).map { .tableau($0) }

    public var isTableau: Bool {
        if case .tableau = self { return true }
        return false
    }

    public var isFoundation: Bool {
        if case .foundation = self { return true }
        return false
    }
}
