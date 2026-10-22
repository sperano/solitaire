import SolitaireKit
import XCTest
@testable import Solitaire

@MainActor
final class GameSettingsTests: XCTestCase {
    private static let invalidStoredMode = 7
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() async throws {
        suiteName = "quebec.spe.SolitaireTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testDefaultDrawModeIsOneWhenSuiteIsEmpty() {
        XCTAssertEqual(GameSettings(defaults: defaults).drawMode, .one)
        XCTAssertEqual(GameSettings.defaultDrawMode, .one)
    }

    func testDrawModePersistsToSuiteAndIsReadBackByNewInstance() {
        let settings = GameSettings(defaults: defaults)
        settings.drawMode = .three

        XCTAssertEqual(defaults.integer(forKey: GameSettings.drawModeKey), DrawMode.three.rawValue)
        XCTAssertEqual(GameSettings(defaults: defaults).drawMode, .three)
    }

    func testInvalidStoredIntegerFallsBackToDefault() {
        defaults.set(Self.invalidStoredMode, forKey: GameSettings.drawModeKey)

        XCTAssertEqual(GameSettings(defaults: defaults).drawMode, GameSettings.defaultDrawMode)
    }
}
