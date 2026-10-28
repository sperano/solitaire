import XCTest

/// Launches the app with the deterministic in-memory configuration.
/// XCUIElement APIs are main-actor isolated, so the whole test case is too.
@MainActor
class SolitaireUITestCase: XCTestCase {
    static let stockSize = 24
    static let columnCount = 7
    static let foundationCount = 4
    static let cardsPerDrawThree = 3
    static let defaultSeed = "42"
    static let timeout: TimeInterval = 5
    /// How long to wait before concluding that something did not appear. Something that goes away (a
    /// closing sheet or alert) is waited for with `waitForNonExistence(timeout: timeout)` instead:
    /// `waitForExistence` returns at once while it is still on screen.
    static let absenceTimeout: TimeInterval = 1
    static let dragHold: TimeInterval = 0.3
    /// Swipes `scrollTo` tries before giving up: enough for the whole Settings form.
    static let maxSwipes = 6

    var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = launchApp()
    }

    /// Launches the app with `extraArguments`; `seed` nil leaves the deal random.
    @discardableResult
    func launchApp(extraArguments: [String] = ["-drawMode", "1"],
                   seed: String? = SolitaireUITestCase.defaultSeed) -> XCUIApplication
    {
        let application = XCUIApplication()
        application.launchArguments = ["--ui-testing"] + (seed.map { ["-seed", $0] } ?? []) + extraArguments
        application.launch()
        return application
    }

    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    /// The accessibility value of a pile, e.g. "24 cards".
    func value(of identifier: String) -> String {
        let target = element(identifier)
        XCTAssertTrue(target.waitForExistence(timeout: Self.timeout), "\(identifier) not found")
        return target.value as? String ?? ""
    }

    /// The accessibility label of an element, e.g. "Column 1".
    func label(of identifier: String) -> String {
        let target = element(identifier)
        XCTAssertTrue(target.waitForExistence(timeout: Self.timeout), "\(identifier) not found")
        return target.label
    }

    func cards(_ identifier: String) -> String { "\(value(of: identifier))" }

    func expectCards(_ count: Int, in identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(value(of: identifier), Self.cardCount(count), identifier, file: file, line: line)
    }

    /// A pile's accessibility value in English: "24 cards", "1 card".
    static func cardCount(_ count: Int) -> String { count == 1 ? "1 card" : "\(count) cards" }

    /// The move counter, read from its accessibility label ("<n> moves", "1 move").
    var moves: String {
        let label = element("movesLabel")
        XCTAssertTrue(label.waitForExistence(timeout: Self.timeout))
        return String(label.label.prefix(while: \.isNumber))
    }

    func tap(_ identifier: String) {
        let target = element(identifier)
        XCTAssertTrue(target.waitForExistence(timeout: Self.timeout), "\(identifier) not found")
        target.tap()
    }

    /// Swipes up until the element is on screen and can be tapped. Settings is a lazily built form:
    /// its lower rows (Statistics, the Deal section) do not exist until scrolled to.
    @discardableResult
    func scrollTo(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let target = element(identifier)
        var swipes = 0
        while !(target.exists && target.isHittable), swipes < Self.maxSwipes {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(target.isHittable, "\(identifier) not reached", file: file, line: line)
        return target
    }

    func tapStock(times: Int = 1) {
        for _ in 0 ..< times { tap("stock") }
    }
}
