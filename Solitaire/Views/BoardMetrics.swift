import SolitaireKit
import SwiftUI

/// Sizes shared by every pile so cards line up and drags can be hit-tested.
struct BoardMetrics {
    static let coordinateSpace = "board"
    static let columnCount = GameState.tableauColumnCount
    static let horizontalPadding: CGFloat = 8
    static let columnSpacing: CGFloat = 6
    static let cardAspectRatio: CGFloat = 1.4
    static let faceDownOffsetRatio: CGFloat = 0.14
    static let faceUpOffsetRatio: CGFloat = 0.30
    static let wasteFanRatio: CGFloat = 0.28
    static let cornerRadiusRatio: CGFloat = 0.08

    let cardWidth: CGFloat

    init(boardWidth: CGFloat) {
        let gaps = CGFloat(Self.columnCount - 1) * Self.columnSpacing
        cardWidth = max(1, (boardWidth - 2 * Self.horizontalPadding - gaps) / CGFloat(Self.columnCount))
    }

    var cardHeight: CGFloat { cardWidth * Self.cardAspectRatio }
    var cardSize: CGSize { CGSize(width: cardWidth, height: cardHeight) }
    var cornerRadius: CGFloat { cardWidth * Self.cornerRadiusRatio }
    var faceDownOffset: CGFloat { cardHeight * Self.faceDownOffsetRatio }
    var faceUpOffset: CGFloat { cardHeight * Self.faceUpOffsetRatio }
    var wasteFanOffset: CGFloat { cardWidth * Self.wasteFanRatio }

    /// Vertical position of each card in a column, compressed so the column fits in `availableHeight`.
    func columnOffsets(for cards: [Card], availableHeight: CGFloat) -> [CGFloat] {
        guard cards.count > 1 else { return cards.map { _ in 0 } }
        let steps = cards.dropLast().map { $0.isFaceUp ? faceUpOffset : faceDownOffset }
        let natural = steps.reduce(0, +)
        let room = max(0, availableHeight - cardHeight)
        let scale = natural > room ? room / natural : 1
        var offsets: [CGFloat] = [0]
        for step in steps {
            offsets.append(offsets[offsets.count - 1] + step * scale)
        }
        return offsets
    }
}

enum Theme {
    static let felt = Color(red: 0.07, green: 0.40, blue: 0.23)
    static let slotStroke = Color.white.opacity(0.35)
    static let cardFace = Color.white
    static let cardBorder = Color.black.opacity(0.25)
    static let cardBack = Color(red: 0.16, green: 0.32, blue: 0.70)
    static let cardBackInner = Color.white.opacity(0.7)
    static let red = Color(red: 0.80, green: 0.10, blue: 0.12)
    static let black = Color.black
}

/// Frames of the piles in board coordinates, used to find the drop target of a drag.
struct PileFramePreferenceKey: PreferenceKey {
    static let defaultValue: [PileID: CGRect] = [:]

    static func reduce(value: inout [PileID: CGRect], nextValue: () -> [PileID: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    func reportFrame(as pile: PileID) -> some View {
        background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: PileFramePreferenceKey.self,
                    value: [pile: geometry.frame(in: .named(BoardMetrics.coordinateSpace))]
                )
            }
        }
    }
}

extension PileID {
    var accessibilityIdentifier: String {
        switch self {
        case .stock: "stock"
        case .waste: "waste"
        case let .foundation(index): "foundation-\(index)"
        case let .tableau(index): "tableau-\(index)"
        }
    }
}

extension Card {
    /// ASCII identifier such as `card-7H`, stable across face changes.
    var accessibilityIdentifier: String {
        "card-\(rank.symbol)\(suit.rawValue.prefix(1).uppercased())"
    }
}
