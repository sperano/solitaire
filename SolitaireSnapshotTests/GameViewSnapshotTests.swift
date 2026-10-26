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

    /// Large print, a few moves in: the bigger corners must still read in the overlapped columns.
    func testMidGameBoardInLargePrint() throws {
        let model = SnapshotFixtures.viewModel(resuming: SnapshotFixtures.midGame())
        model.settings.largePrint = true
        try assertScreen(GameView(viewModel: model))
    }

    /// Left-handed: stock and waste on the right, three drawn cards fanning left into the gap.
    func testLeftHandedBoardWithAFannedWaste() throws {
        var game = Game(seed: SnapshotFixtures.seed, drawMode: .three, scoringMode: GameSettings.defaultScoringMode)
        try game.perform(.draw)
        let model = SnapshotFixtures.viewModel(resuming: game)
        model.settings.leftHanded = true
        try assertScreen(GameView(viewModel: model))
    }
}
