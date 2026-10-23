import SolitaireKit
import XCTest
@testable import Solitaire

final class DealNumberTests: XCTestCase {
    private static let number: UInt64 = 123_456_789

    func testFormatGroupsDigits() {
        XCTAssertEqual(DealNumber.format(Self.number).filter(\.isWholeNumber), "123456789")
        XCTAssertNotEqual(DealNumber.format(Self.number), "123456789", "digits are grouped")
        XCTAssertEqual(DealNumber.format(7), "7")
    }

    func testParseAcceptsDigitsWithOrWithoutGrouping() {
        XCTAssertEqual(DealNumber.parse("123456789"), Self.number)
        XCTAssertEqual(DealNumber.parse(DealNumber.format(Self.number)), Self.number)
        XCTAssertEqual(DealNumber.parse(" 42 "), 42)
        XCTAssertEqual(DealNumber.parse("deal 42"), 42)
    }

    func testParseRejectsNothingZeroAndNumbersOutOfRange() {
        XCTAssertNil(DealNumber.parse(""))
        XCTAssertNil(DealNumber.parse("abc"))
        XCTAssertNil(DealNumber.parse("0"))
        XCTAssertEqual(DealNumber.parse(String(GameState.dealNumberRange.upperBound)), GameState.dealNumberRange.upperBound)
        XCTAssertNil(DealNumber.parse(String(GameState.dealNumberRange.upperBound + 1)))
        XCTAssertNil(DealNumber.parse("99999999999999999999999"), "longer than any UInt64")
    }

    func testShareTextNamesTheDealAndTheDrawMode() {
        let text = DealNumber.shareText(Self.number, drawMode: .three)
        XCTAssertTrue(text.contains(DealNumber.format(Self.number)))
        XCTAssertTrue(text.contains(DrawMode.three.title))
    }
}
