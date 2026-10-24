import SnapshotTesting
import SolitaireKit
import SwiftUI
import XCTest
@testable import Solitaire

/// The board at the screen sizes the layout must handle, in both orientations: the smallest
/// iPhone, the largest, and a large iPad. Light mode only; dark mode is covered on the iPhone 17.
final class LayoutSnapshotTests: SnapshotTestCase {
    /// The screens the layout is checked at, as the snapshot library describes them.
    enum Device: String, CaseIterable {
        /// 320 × 568 pt, also the width of a one-third Split View pane.
        case iPhoneSE
        /// 428 × 926 pt with a notch, the library's largest iPhone.
        case iPhoneProMax
        /// 1024 × 1366 pt.
        case iPadPro

        func config(_ orientation: ViewImageConfig.Orientation) -> ViewImageConfig {
            switch self {
            case .iPhoneSE: .iPhoneSe(orientation)
            case .iPhoneProMax: .iPhone13ProMax(orientation)
            case .iPadPro: .iPadPro12_9(orientation)
            }
        }
    }

    private static let orientations: [(name: String, value: ViewImageConfig.Orientation)] = [
        ("portrait", .portrait), ("landscape", .landscape),
    ]

    func testTheDealOnEveryScreen() {
        forEveryScreen { config, name in
            assertLayout(GameView(viewModel: SnapshotFixtures.viewModel()), config: config, named: name)
        }
    }

    /// Mid-game with a run lifted, where landscape has to compress the columns.
    func testAMidGameBoardOnEveryScreen() throws {
        let game = SnapshotFixtures.midGame()
        try forEveryScreen { config, name in
            let model = SnapshotFixtures.viewModel(resuming: game)
            model.drag = try XCTUnwrap(SnapshotFixtures.liftedRun(in: model.state), "no column holds a run to lift")
            assertLayout(GameView(viewModel: model), config: config, named: name)
        }
    }

    private func forEveryScreen(_ body: (ViewImageConfig, String) throws -> Void) rethrows {
        for device in Device.allCases {
            for orientation in Self.orientations {
                try body(device.config(orientation.value), "\(device.rawValue)-\(orientation.name)")
            }
        }
    }
}
