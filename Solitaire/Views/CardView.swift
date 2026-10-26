import SolitaireKit
import SwiftUI

struct CardView: View {
    private static let cornerFontRatio: CGFloat = 0.28
    private static let centerFontRatio: CGFloat = 0.55
    private static let cornerInsetRatio: CGFloat = 0.07
    /// Large print: rank and suit on one line, sized to the strip a covered card shows in a column
    /// (`BoardMetrics.faceUpOffsetRatio`), and a smaller suit low in the middle, clear of them.
    private static let largeCornerFontRatio: CGFloat = 0.38
    private static let largeCornerInsetRatio: CGFloat = 0.04
    private static let largeCenterFontRatio: CGFloat = 0.5
    private static let largeCenterBottomInsetRatio: CGFloat = 0.1
    /// "10♥" shrinks this far rather than run past the card's edge.
    private static let largeMinimumScale: CGFloat = 0.7
    static let hintBorderWidth: CGFloat = 3
    static let flipSeconds = 0.3

    let card: Card
    let metrics: BoardMetrics
    /// Part of the move a hint shows.
    var isHinted = false
    @Environment(\.cardStyle) private var style
    @Environment(\.cardsInFlight) private var cardsInFlight
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// "Seven of hearts, face up", or "Face-down card" for a card whose face is hidden.
    static func accessibilityLabel(for card: Card) -> String {
        guard card.isFaceUp else { return String(localized: "Face-down card") }
        let name = card.spokenName
        let capitalised = name.prefix(1).uppercased(with: .current) + name.dropFirst()
        return String(localized: "\(capitalised), face up", comment: "A face-up card, its name capitalised")
    }

    var body: some View {
        FlipView(isFaceUp: card.isFaceUp) { face } back: { CardBackView(metrics: metrics) }
            .animation(
                Motion.animation(.easeInOut(duration: Self.flipSeconds), reduceMotion: reduceMotion),
                value: card.isFaceUp
            )
            // The glyphs are sized to the card, not to Dynamic Type; VoiceOver reads the card's name instead.
            .accessibilityHidden(true)
            .frame(width: metrics.cardWidth, height: metrics.cardHeight)
            .overlay {
                if isHinted {
                    shape.strokeBorder(Theme.hint, lineWidth: Self.hintBorderWidth)
                }
            }
            // One element the size of the card, not one per rank and suit text inside it.
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier(card.accessibilityIdentifier)
            .accessibilityLabel(Self.accessibilityLabel(for: card))
            .accessibilityAddTraits(isHinted ? .isSelected : [])
            // A copy flies above the board; this one appears, and can be touched, when it lands.
            .opacity(cardsInFlight.contains(card.id) ? 0 : 1)
            .allowsHitTesting(!cardsInFlight.contains(card.id))
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
    }

    private var inkColor: Color { style.ink(for: card.suit) }

    private var face: some View {
        ZStack(alignment: .topLeading) {
            shape.fill(Theme.cardFace)
            shape.strokeBorder(style.border, lineWidth: style.borderWidth)
            if style.isLargePrint { largePrint } else { standardPrint }
        }
        .foregroundStyle(inkColor)
    }

    @ViewBuilder
    private var standardPrint: some View {
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

    @ViewBuilder
    private var largePrint: some View {
        Text(card.suit.symbol)
            .font(.system(size: metrics.cardWidth * Self.largeCenterFontRatio))
            .padding(.bottom, metrics.cardWidth * Self.largeCenterBottomInsetRatio)
            .frame(width: metrics.cardWidth, height: metrics.cardHeight, alignment: .bottom)
        Text(card.rank.symbol + card.suit.symbol)
            .font(.system(size: metrics.cardWidth * Self.largeCornerFontRatio, weight: .bold, design: .rounded))
            .minimumScaleFactor(Self.largeMinimumScale)
            .lineLimit(1)
            .padding(.horizontal, metrics.cardWidth * Self.largeCornerInsetRatio)
            .frame(width: metrics.cardWidth, alignment: .leading)
    }
}

/// The outline drawn where a pile has no cards.
struct EmptySlotView: View {
    private static let symbolRatio: CGFloat = 0.4

    let metrics: BoardMetrics
    var symbol: String?
    /// The pile a hint points at.
    var isHinted = false

    @Environment(\.cardStyle) private var style

    var body: some View {
        RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
            .strokeBorder(
                isHinted ? Theme.hint : style.slotStroke,
                lineWidth: isHinted ? CardView.hintBorderWidth : style.slotStrokeWidth
            )
            .overlay {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: metrics.cardWidth * Self.symbolRatio))
                        .foregroundStyle(style.slotStroke)
                }
            }
            .frame(width: metrics.cardWidth, height: metrics.cardHeight)
    }
}
