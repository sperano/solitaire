import SwiftUI
import XCTest
@testable import Solitaire

final class TableColoursTests: XCTestCase {
    /// WCAG AA for normal text: the toolbar's white labels sit on the felt.
    private static let minimumTextContrast: CGFloat = 4.5

    func testWhiteTextIsReadableOnEveryFelt() {
        for felt in TableFelt.allCases {
            let ratio = Self.contrast(UIColor(felt.color), .white)
            XCTAssertGreaterThanOrEqual(ratio, Self.minimumTextContrast, "\(felt): \(ratio)")
        }
    }

    /// The launch screen and the icon are this green; the default felt must not drift from it.
    func testTheGreenFeltIsTheLaunchScreenGreen() {
        XCTAssertEqual(TableFelt.green.color, Theme.felt)
    }

    func testTheBlueBackIsTheIconsBack() {
        XCTAssertEqual(CardBack.blue.color, Theme.cardBack)
    }

    func testFeltsAndBacksAreAllDifferent() {
        XCTAssertEqual(Set(TableFelt.allCases.map(\.color)).count, TableFelt.allCases.count)
        XCTAssertEqual(Set(CardBack.allCases.map(\.color)).count, CardBack.allCases.count)
    }

    func testEveryBackHasItsOwnPattern() {
        let patterns = CardBack.allCases.map { "\($0.pattern)" }
        XCTAssertEqual(Set(patterns).count, CardBack.allCases.count)
    }

    /// WCAG contrast ratio between two opaque sRGB colours.
    private static func contrast(_ first: UIColor, _ second: UIColor) -> CGFloat {
        let lighter = max(luminance(first), luminance(second))
        let darker = min(luminance(first), luminance(second))
        return (lighter + WCAG.flare) / (darker + WCAG.flare)
    }

    private static func luminance(_ color: UIColor) -> CGFloat {
        let linear = color.rgba.prefix(WCAG.weights.count).map { channel in
            channel <= WCAG.linearLimit
                ? channel / WCAG.linearSlope
                : pow((channel + WCAG.gammaOffset) / (1 + WCAG.gammaOffset), WCAG.gamma)
        }
        return zip(linear, WCAG.weights).map(*).reduce(0, +)
    }
}

/// The sRGB relative luminance and contrast ratio constants of WCAG 2.
private enum WCAG {
    static let linearLimit: CGFloat = 0.039_28
    static let linearSlope: CGFloat = 12.92
    static let gammaOffset: CGFloat = 0.055
    static let gamma: CGFloat = 2.4
    /// Red, green and blue weights of the luminance.
    static let weights: [CGFloat] = [0.2126, 0.7152, 0.0722]
    static let flare: CGFloat = 0.05
}
