public enum Move: Hashable, Codable, Sendable {
    /// Turn cards from the stock onto the waste, or recycle the waste into the stock when the stock is empty.
    case draw
    /// Move the top `count` cards of `from` onto `to`.
    case move(from: PileID, to: PileID, count: Int)
}

public enum MoveError: Error, Equatable, Sendable {
    case nothingToDraw
    /// Vegas scoring limits how many times the waste can go back to the stock.
    case noPassesLeft
    case sameDestination
    case invalidCount
    case faceDownCard
    case illegalSource
    case illegalDestination
    case illegalPlacement
}
