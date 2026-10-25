import XCTest

/// The board fits the screen in both orientations: every pile stays on screen, the top row sits
/// above the tableau and the columns never run off the bottom. Runs on iPhone and iPad alike;
/// CI runs it on both.
final class LayoutUITests: SolitaireUITestCase {
    private static let piles = ["stock", "waste"] + (0 ..< foundationCount).map { "foundation-\($0)" }
        + (0 ..< columnCount).map { "tableau-\($0)" }
    /// Rotation animates; the frames are read once they stop changing.
    private static let rotationSettleTimeout: TimeInterval = 2

    override func tearDown() async throws {
        XCUIDevice.shared.orientation = .portrait
    }

    func testLandscapeKeepsTheWholeBoardOnScreen() {
        rotate(to: .landscapeLeft)
        XCTAssertGreaterThan(app.frame.width, app.frame.height, "the window did not turn")
        expectBoardFits()
    }

    func testTurningBackToPortraitRestoresTheBoard() {
        rotate(to: .landscapeLeft)
        rotate(to: .portrait)
        XCTAssertGreaterThan(app.frame.height, app.frame.width, "the window did not turn back")
        expectBoardFits()
    }

    func testMovesWorkInLandscape() {
        rotate(to: .landscapeLeft)
        tap("card-AH")
        expectCards(1, in: "foundation-0")
        tapStock()
        expectCards(1, in: "waste")
        XCTAssertEqual(moves, "2")
    }

    func testLeftHandedLayoutPutsTheStockOnTheRight() {
        tap("settingsButton")
        let toggle = app.switches["leftHandedToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: Self.timeout))
        XCTAssertEqual(toggle.value as? String, "0")
        toggle.switches.firstMatch.tap()
        tap("settingsDoneButton")

        let window = app.frame
        XCTAssertTrue(element("stock").waitForExistence(timeout: Self.timeout))
        XCTAssertGreaterThan(element("stock").frame.minX, window.midX, "the stock is not on the right half")
        let lastFoundation = element("foundation-\(Self.foundationCount - 1)").frame
        XCTAssertGreaterThan(
            element("waste").frame.minX,
            lastFoundation.maxX,
            "the waste is not right of the foundations"
        )
        expectBoardFits()
        tapStock()
        expectCards(1, in: "waste")
    }

    private func rotate(to orientation: UIDeviceOrientation) {
        XCUIDevice.shared.orientation = orientation
        let window = app.frame
        let turned = orientation.isLandscape ? window.width > window.height : window.height > window.width
        if !turned {
            // Give the rotation its animation time, then read the frame again.
            _ = element("stock").waitForExistence(timeout: Self.rotationSettleTimeout)
        }
    }

    /// Every pile is on screen, the top row is above the tableau and the tallest column fits.
    private func expectBoardFits(file: StaticString = #filePath, line: UInt = #line) {
        let window = app.frame
        var frames: [String: CGRect] = [:]
        for pile in Self.piles {
            let target = element(pile)
            XCTAssertTrue(target.waitForExistence(timeout: Self.timeout), "\(pile) not found", file: file, line: line)
            frames[pile] = target.frame
            XCTAssertTrue(
                window.contains(target.frame),
                "\(pile) at \(target.frame) leaves the window \(window)",
                file: file,
                line: line
            )
        }
        let topRowBottom = (["stock", "waste"] + (0 ..< Self.foundationCount).map { "foundation-\($0)" })
            .compactMap { frames[$0]?.maxY }.max() ?? 0
        let tableauTop = (0 ..< Self.columnCount).compactMap { frames["tableau-\($0)"]?.minY }.min() ?? 0
        XCTAssertLessThanOrEqual(topRowBottom, tableauTop, "the top row overlaps the tableau", file: file, line: line)
        // The last column holds the most cards at the deal; its bottom card must be inside its frame.
        let lastColumn = frames["tableau-\(Self.columnCount - 1)"] ?? .zero
        let bottomCard = element("card-AH").frame
        XCTAssertTrue(lastColumn.contains(bottomCard), "the deal's longest column overflows", file: file, line: line)
    }
}
