import SolitaireKit
import SwiftUI

struct CardView: View {
    private static let cornerFontRatio: CGFloat = 0.28
    private static let centerFontRatio: CGFloat = 0.55
    private static let cornerInsetRatio: CGFloat = 0.07
    private static let backInsetRatio: CGFloat = 0.1
    private static let borderWidth: CGFloat = 1
    private static let backInnerBorderWidth: CGFloat = 1.5

    let card: Card
    let metrics: BoardMetrics

    var body: some View {
        Group {
            if card.isFaceUp {
                face
            } else {
                back
            }
        }
        .frame(width: metrics.cardWidth, height: metrics.cardHeight)
        .accessibilityIdentifier(card.accessibilityIdentifier)
        .accessibilityLabel(card.isFaceUp ? card.name : "face-down card")
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
    }

    private var inkColor: Color {
        card.color == .red ? Theme.red : Theme.black
    }

    private var face: some View {
        ZStack(alignment: .topLeading) {
            shape.fill(Theme.cardFace)
            shape.strokeBorder(Theme.cardBorder, lineWidth: Self.borderWidth)
            Text(card.suit.symbol)
                .font(.system(size: metrics.cardWidth * Self.centerFontRatio))
                .frame(width: metrics.cardWidth, height: metrics.cardHeight)
            VStack(alignment: .leading, spacing: 0) {
                Text(card.rank.symbol)
                Text(card.suit.symbol)
            }
            .font(.system(size: metrics.cardWidth * Self.cornerFontRatio, weight: .semibold, design: .rounded))
            .padding(metrics.cardWidth * Self.cornerInsetRatio)
        }
        .foregroundStyle(inkColor)
    }

    private var back: some View {
        ZStack {
            shape.fill(Theme.cardBack)
            shape.strokeBorder(Theme.cardBorder, lineWidth: Self.borderWidth)
            shape
                .inset(by: metrics.cardWidth * Self.backInsetRatio)
                .strokeBorder(Theme.cardBackInner, lineWidth: Self.backInnerBorderWidth)
        }
    }
}

/// The outline drawn where a pile has no cards.
struct EmptySlotView: View {
    private static let symbolRatio: CGFloat = 0.4
    private static let strokeWidth: CGFloat = 1.5

    let metrics: BoardMetrics
    var symbol: String?

    var body: some View {
        RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
            .strokeBorder(Theme.slotStroke, lineWidth: Self.strokeWidth)
            .overlay {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: metrics.cardWidth * Self.symbolRatio))
                        .foregroundStyle(Theme.slotStroke)
                }
            }
            .frame(width: metrics.cardWidth, height: metrics.cardHeight)
    }
}
