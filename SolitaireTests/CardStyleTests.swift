import SolitaireKit
import SwiftUI
import XCTest
@testable import Solitaire

final class CardStyleTests: XCTestCase {
    private let styles = [false, true].flatMap { four in
        [false, true].map { CardStyle(isFourColour: four, isHighContrast: $0) }
    }

    func testTwoColourDeckSharesInkByColour() {
        for style in styles where !style.isFourColour {
            XCTAssertEqual(style.ink(for: .hearts), style.ink(for: .diamonds))
            XCTAssertEqual(style.ink(for: .spades), style.ink(for: .clubs))
            XCTAssertNotEqual(style.ink(for: .hearts), style.ink(for: .spades))
        }
    }

    func testFourColourDeckGivesEverySuitItsOwnInk() {
        for style in styles where style.isFourColour {
            XCTAssertEqual(Set(Suit.allCases.map { style.ink(for: $0) }).count, Suit.allCases.count)
        }
    }

    func testFourColourKeepsTheTraditionalHeartsAndSpades() {
        for highContrast in [false, true] {
            let two = CardStyle(isFourColour: false, isHighContrast: highContrast)
            let four = CardStyle(isFourColour: true, isHighContrast: highContrast)
            XCTAssertEqual(four.ink(for: .hearts), two.ink(for: .hearts))
            XCTAssertEqual(four.ink(for: .spades), two.ink(for: .spades))
        }
    }

    func testHighContrastDarkensTheColouredInks() {
        let standard = CardStyle(isFourColour: true, isHighContrast: false)
        let contrast = CardStyle(isFourColour: true, isHighContrast: true)
        for suit in [Suit.hearts, .diamonds, .clubs] {
            XCTAssertNotEqual(standard.ink(for: suit), contrast.ink(for: suit), "\(suit)")
        }
    }

    func testHighContrastStrengthensBordersAndSlots() {
        let standard = CardStyle.standard
        let contrast = CardStyle(isFourColour: false, isHighContrast: true)
        XCTAssertGreaterThan(contrast.borderWidth, standard.borderWidth)
        XCTAssertGreaterThan(contrast.slotStrokeWidth, standard.slotStrokeWidth)
        XCTAssertEqual(contrast.border, Theme.highContrastBorder)
        XCTAssertNotEqual(contrast.slotStroke, standard.slotStroke)
        XCTAssertNotEqual(contrast.backInner, standard.backInner)
    }

    func testStandardIsTheDefault() {
        XCTAssertEqual(EnvironmentValues().cardStyle, .standard)
        XCTAssertFalse(CardStyle.standard.isFourColour || CardStyle.standard.isHighContrast)
    }
}
