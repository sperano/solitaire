/// How many cards a draw turns from the stock onto the waste.
public enum DrawMode: Int, Codable, CaseIterable, Sendable, Identifiable {
    case one = 1
    case three = 3

    public var id: Int { rawValue }

    public var cardsPerDraw: Int { rawValue }

    public var title: String {
        switch self {
        case .one: "Draw 1"
        case .three: "Draw 3"
        }
    }
}
