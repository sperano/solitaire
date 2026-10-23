import SolitaireKit
import SwiftUI
import XCTest
@testable import Solitaire

final class GameViewSnapshotTests: SnapshotTestCase {
    /// The board right after the deal, before any move.
    func testBoardAtTheDeal() throws {
        try assertScreen(GameView(viewModel: SnapshotFixtures.viewModel()))
    }

    /// A few moves in, with a run lifted off its column as during a drag.
    func testMidGameBoardWithALiftedRun() throws {
        let model = SnapshotFixtures.viewModel(resuming: SnapshotFixtures.midGame())
        model.drag = try XCTUnwrap(SnapshotFixtures.liftedRun(in: model.state), "no column holds a run to lift")
        try assertScreen(GameView(viewModel: model))
    }
}
