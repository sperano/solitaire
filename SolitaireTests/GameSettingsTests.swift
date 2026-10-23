import SolitaireKit
import XCTest
@testable import Solitaire

@MainActor
final class GameSettingsTests: XCTestCase {
    private static let invalidStoredMode = 7
    private static let balance = -104
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

    func testDefaultScoringModeIsStandardWhenSuiteIsEmpty() {
        XCTAssertEqual(GameSettings(defaults: defaults).scoringMode, .standard)
        XCTAssertEqual(GameSettings.defaultScoringMode, .standard)
    }

    func testStoredNoScoringIsNotMistakenForAMissingValue() {
        defaults.set(ScoringMode.none.rawValue, forKey: GameSettings.scoringModeKey)
        XCTAssertEqual(GameSettings(defaults: defaults).scoringMode, ScoringMode.none)
    }

    func testScoringModePersists() {
        GameSettings(defaults: defaults).scoringMode = .vegas
        XCTAssertEqual(GameSettings(defaults: defaults).scoringMode, .vegas)
    }

    func testInvalidStoredScoringModeFallsBackToDefault() {
        defaults.set(Self.invalidStoredMode, forKey: GameSettings.scoringModeKey)
        XCTAssertEqual(GameSettings(defaults: defaults).scoringMode, GameSettings.defaultScoringMode)
    }

    func testVegasBalanceIsCarriedOnlyWhenEnabledAndPersists() {
        let settings = GameSettings(defaults: defaults)
        XCTAssertFalse(settings.carryVegasBalance)
        settings.carryVegasBalance = true
        settings.vegasBalance = Self.balance
        XCTAssertEqual(settings.carriedVegasBalance, Self.balance)

        let reloaded = GameSettings(defaults: defaults)
        XCTAssertTrue(reloaded.carryVegasBalance)
        XCTAssertEqual(reloaded.vegasBalance, Self.balance)
    }

    func testTurningCarryOffClearsTheBalance() {
        let settings = GameSettings(defaults: defaults)
        settings.carryVegasBalance = true
        settings.vegasBalance = Self.balance
        settings.carryVegasBalance = false

        XCTAssertEqual(settings.vegasBalance, 0)
        XCTAssertEqual(settings.carriedVegasBalance, 0)
        XCTAssertEqual(GameSettings(defaults: defaults).vegasBalance, 0)
    }

    func testAutoFinishIsOffByDefaultAndPersists() {
        let settings = GameSettings(defaults: defaults)
        XCTAssertFalse(settings.autoFinish)
        settings.autoFinish = true
        XCTAssertTrue(defaults.bool(forKey: GameSettings.autoFinishKey))
        XCTAssertTrue(GameSettings(defaults: defaults).autoFinish)
    }

    func testFourColorDeckIsOffByDefaultAndPersists() {
        let settings = GameSettings(defaults: defaults)
        XCTAssertFalse(settings.fourColorDeck)
        settings.fourColorDeck = true
        XCTAssertTrue(defaults.bool(forKey: GameSettings.fourColorDeckKey))
        XCTAssertTrue(GameSettings(defaults: defaults).fourColorDeck)
    }

    func testHapticsAreOnByDefaultAndPersist() {
        let settings = GameSettings(defaults: defaults)
        XCTAssertTrue(settings.haptics)
        settings.haptics = false
        XCTAssertEqual(defaults.object(forKey: GameSettings.hapticsKey) as? Bool, false)
        XCTAssertFalse(GameSettings(defaults: defaults).haptics)
    }

    func testWinnableDealsOnlyIsOffByDefaultAndPersists() {
        let settings = GameSettings(defaults: defaults)
        XCTAssertFalse(settings.winnableDealsOnly)
        settings.winnableDealsOnly = true
        XCTAssertTrue(defaults.bool(forKey: GameSettings.winnableDealsOnlyKey))
        XCTAssertTrue(GameSettings(defaults: defaults).winnableDealsOnly)
    }
}
