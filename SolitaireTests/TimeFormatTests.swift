import XCTest
@testable import Solitaire

final class TimeFormatTests: XCTestCase {
    private static let cases: [(seconds: Int, text: String)] = [
        (0, "0:00"), (5, "0:05"), (59, "0:59"), (60, "1:00"), (65, "1:05"), (3_600, "60:00"), (3_725, "62:05"),
    ]

    func testMinutesAndSeconds() {
        for (seconds, text) in Self.cases {
            XCTAssertEqual(TimeFormat.minutesAndSeconds(seconds), text, "\(seconds)")
        }
    }

    func testNegativeInputShowsZero() {
        XCTAssertEqual(TimeFormat.minutesAndSeconds(-5), "0:00")
    }
}
