import SolitaireKit
import SwiftUI
import XCTest
@testable import Solitaire

final class SettingsViewSnapshotTests: SnapshotTestCase {
    func testDefaultSettings() throws {
        try assertScreen(settingsView(SnapshotFixtures.settings()))
    }

    /// Vegas scoring and winnable deals add a toggle and a longer footer to the Rules section.
    func testVegasSettings() throws {
        let settings = SnapshotFixtures.settings()
        settings.drawMode = .three
        settings.scoringMode = .vegas
        settings.winnableDealsOnly = true
        try assertScreen(settingsView(settings))
    }

    private func settingsView(_ settings: GameSettings) -> SettingsView {
        SettingsView(
            settings: settings, statistics: SnapshotFixtures.statistics(), dealNumber: SnapshotFixtures.seed,
            drawMode: settings.drawMode, isGameStarted: true, playDeal: { _ in }
        )
    }
}
