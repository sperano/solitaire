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

    func testLargePrintDeck() {
        assertFitted(DeckSheet(style: CardStyle(isFourColour: false, isHighContrast: false, isLargePrint: true)))
    }

    func testLargePrintHighContrastDeck() {
        assertFitted(DeckSheet(style: CardStyle(isFourColour: false, isHighContrast: true, isLargePrint: true)))
    }

    func testCardBacksOnEveryFelt() {
        assertFitted(FeltSheet(isHighContrast: false))
    }

    func testHighContrastCardBacksOnEveryFelt() {
        assertFitted(FeltSheet(isHighContrast: true))
    }
}

/// One row per felt: each card back, a face and an empty slot on it.
private struct FeltSheet: View {
    let isHighContrast: Bool

    var body: some View {
        let metrics = BoardMetrics(boardSize: DeckSheet.boardSize)
        VStack(spacing: 0) {
            ForEach(TableFelt.allCases) { felt in
                HStack(spacing: BoardMetrics.columnSpacing) {
                    ForEach(CardBack.allCases) { back in
                        CardView(card: Card(suit: .spades, rank: .ace), metrics: metrics)
                            .environment(\.cardStyle, style(back: back))
                    }
                    CardView(card: Card(suit: .hearts, rank: .queen, isFaceUp: true), metrics: metrics)
                    EmptySlotView(metrics: metrics)
                }
                .padding(BoardMetrics.horizontalPadding)
                .background(felt.color)
                .environment(\.cardStyle, style(back: .defaultValue))
            }
        }
    }

    private func style(back: CardBack) -> CardStyle {
        CardStyle(isFourColour: false, isHighContrast: isHighContrast, back: back)
    }
}

/// The faces by suit and rank, then the back, a hinted card and the empty slots, on the felt, at
/// the size the board draws cards on the snapshot device.
private struct DeckSheet: View {
    /// The snapshot device's screen width, so the cards are the size the board draws them.
    /// The iPhone 17 screen, so the cards are the size the board snapshots show.
    static let boardSize = CGSize(width: 402, height: 874)

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
