import SolitaireKit
import SwiftUI
import XCTest
@testable import Solitaire

/// Every card face and the card back in each card style.
final class CardViewSnapshotTests: SnapshotTestCase {
    func testStandardDeck() {
        assertFitted(DeckSheet(style: .standard))
    }

    func testFourColourDeck() {
        assertFitted(DeckSheet(style: CardStyle(isFourColour: true, isHighContrast: false)))
    }

    func testHighContrastDeck() {
        assertFitted(DeckSheet(style: CardStyle(isFourColour: false, isHighContrast: true)))
    }

    func testHighContrastFourColourDeck() {
        assertFitted(DeckSheet(style: CardStyle(isFourColour: true, isHighContrast: true)))
    }
}

/// The faces by suit and rank, then the back, a hinted card and the empty slots, on the felt, at
/// the size the board draws cards on the snapshot device.
private struct DeckSheet: View {
    /// The snapshot device's screen width, so the cards are the size the board draws them.
    /// The iPhone 17 screen, so the cards are the size the board snapshots show.
    private static let boardSize = CGSize(width: 402, height: 874)

    let style: CardStyle

    var body: some View {
        let metrics = BoardMetrics(boardSize: Self.boardSize)
        VStack(alignment: .leading, spacing: BoardMetrics.columnSpacing) {
            ForEach(Suit.allCases, id: \.self) { suit in
                HStack(spacing: BoardMetrics.columnSpacing) {
                    ForEach(Rank.allCases, id: \.self) { rank in
                        CardView(card: Card(suit: suit, rank: rank, isFaceUp: true), metrics: metrics)
                    }
                }
            }
            HStack(spacing: BoardMetrics.columnSpacing) {
                CardView(card: Card(suit: .spades, rank: .ace), metrics: metrics)
                CardView(card: Card(suit: .hearts, rank: .seven, isFaceUp: true), metrics: metrics, isHinted: true)
                EmptySlotView(metrics: metrics)
                EmptySlotView(metrics: metrics, isHinted: true)
            }
        }
        .padding(BoardMetrics.horizontalPadding)
        .background(Theme.felt)
        .environment(\.cardStyle, style)
    }
}
