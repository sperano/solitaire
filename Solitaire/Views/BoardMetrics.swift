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
    /// Between the top row and the tableau, and above and below them.
    static let rowSpacing: CGFloat = 12
    /// Vertical padding above and below the board, plus the gap between its two rows.
    static let verticalGapCount: CGFloat = 3
    /// Card heights the tableau gets below the top row before the cards shrink to fit the board's
    /// height: room for the deal's longest column (six cards face down under one face up) and
    /// then some. In portrait the width limits the cards and the tableau gets the rest of the screen.
    static let tableauCardHeights: CGFloat = 2.5

    let cardWidth: CGFloat

    /// Cards as wide as the board allows, and no taller than its height allows: in landscape, and in
    /// a short Stage Manager window, the height is what binds, and the board is centred.
    init(boardSize: CGSize) {
        let gaps = CGFloat(Self.columnCount - 1) * Self.columnSpacing
        let widthLimited = (boardSize.width - 2 * Self.horizontalPadding - gaps) / CGFloat(Self.columnCount)
        let rowsHeight = boardSize.height - Self.verticalGapCount * Self.rowSpacing
        let heightLimited = rowsHeight / ((1 + Self.tableauCardHeights) * Self.cardAspectRatio)
        cardWidth = max(1, min(widthLimited, heightLimited))
    }

    /// What is left for the tableau under the top row in a board `boardHeight` tall, never less than a card.
    func tableauHeight(boardHeight: CGFloat) -> CGFloat {
        max(cardHeight, boardHeight - cardHeight - Self.verticalGapCount * Self.rowSpacing)
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
    /// The table. A colour asset so the launch screen (`UILaunchScreen` in project.yml) and the
    /// app icon's background (`Design/AppIcon.svg`) can be the same green: no flash at launch.
    static let felt = Color(.felt)
    static let slotStroke = Color.white.opacity(0.35)
    static let cardFace = Color.white
    static let cardBorder = Color.black.opacity(0.25)
    static let cardBack = Color(red: 0.16, green: 0.32, blue: 0.70)
    static let cardBackInner = Color.white.opacity(0.7)
    static let red = Color(red: 0.80, green: 0.10, blue: 0.12)
    static let black = Color.black
    static let blue = Color(red: 0.05, green: 0.30, blue: 0.80)
    static let green = Color(red: 0.00, green: 0.50, blue: 0.15)
    /// Darker inks for Increase Contrast, each at least 7:1 against the white card face.
    static let highContrastRed = Color(red: 0.62, green: 0.00, blue: 0.00)
    static let highContrastBlue = Color(red: 0.00, green: 0.17, blue: 0.55)
    static let highContrastGreen = Color(red: 0.00, green: 0.30, blue: 0.08)
    /// Section footers in Settings and Statistics; the system grey falls just short of 4.5:1.
    static let formFooter = Color.primary.opacity(0.75)
    static let highContrastBorder = Color.black
    static let highContrastSlotStroke = Color.white.opacity(0.85)
    static let highContrastBackInner = Color.white
    /// Outline of the cards and empty slots a hint points at.
    static let hint = Color.yellow
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
