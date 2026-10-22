import XCTest

/// Launches the app with the deterministic in-memory configuration.
class SolitaireUITestCase: XCTestCase {
    static let stockSize = 24
    static let columnCount = 7
    static let foundationCount = 4
    static let cardsPerDrawThree = 3
    static let defaultSeed = "42"
    static let timeout: TimeInterval = 5
    static let dragHold: TimeInterval = 0.3

    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = launchApp()
    }

    /// Terminates the current app and relaunches it with `extraArguments`.
    @discardableResult
    func launchApp(extraArguments: [String] = ["-drawMode", "1"]) -> XCUIApplication {
        let application = XCUIApplication()
        application.launchArguments = ["--ui-testing", "-seed", Self.defaultSeed] + extraArguments
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

    func cards(_ identifier: String) -> String { "\(value(of: identifier))" }

    func expectCards(_ count: Int, in identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(value(of: identifier), "\(count) cards", identifier, file: file, line: line)
    }

    /// The move counter, read from its accessibility label ("<n> moves").
    var moves: String {
        let label = element("movesLabel")
        XCTAssertTrue(label.waitForExistence(timeout: Self.timeout))
        return label.label.replacingOccurrences(of: " moves", with: "")
    }

    func tap(_ identifier: String) {
        let target = element(identifier)
        XCTAssertTrue(target.waitForExistence(timeout: Self.timeout), "\(identifier) not found")
        target.tap()
    }

    func tapStock(times: Int = 1) {
        for _ in 0 ..< times { tap("stock") }
    }
}
