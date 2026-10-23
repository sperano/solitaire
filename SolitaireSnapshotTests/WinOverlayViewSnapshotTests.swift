import SolitaireKit
import SwiftUI
import XCTest
@testable import Solitaire

final class WinOverlayViewSnapshotTests: SnapshotTestCase {
    /// The dim and the win panel on their own: the cascade the board plays under them is driven by
    /// the clock, and Reduce Motion, which would drop it, cannot be set from a test.
    func testWinPanel() throws {
        let model = SnapshotFixtures.viewModel(
            resuming: SnapshotFixtures.wonGame(), elapsedSeconds: SnapshotFixtures.wonGameSeconds
        )
        try assertScreen(WinOverlayView(viewModel: model, celebration: { _ in nil }))
    }
}
