import SwiftUI
import XCTest
@testable import Solitaire

/// The launch screen is a plain colour (`UILaunchScreen` in project.yml). It has to be the felt
/// the board paints first, or the app flashes at launch.
final class LaunchScreenTests: XCTestCase {
    private static let feltAssetName = "Felt"
    /// Well under one 8-bit step (1/255).
    private static let componentAccuracy: CGFloat = 0.0001
    private let appBundle = Bundle(for: GameViewModel.self)

    func testTheLaunchScreenIsTheFeltColourAsset() throws {
        let launchScreen = try XCTUnwrap(appBundle.infoDictionary?["UILaunchScreen"] as? [String: Any])
        XCTAssertEqual(launchScreen["UIColorName"] as? String, Self.feltAssetName)
        XCTAssertNotNil(UIColor(named: Self.feltAssetName, in: appBundle, compatibleWith: nil))
    }

    func testTheBoardPaintsTheSameFeltAsTheLaunchScreen() throws {
        let asset = try XCTUnwrap(UIColor(named: Self.feltAssetName, in: appBundle, compatibleWith: nil))
        // SwiftUI keeps the components as Float, so they differ from the asset's past 7 digits.
        for (board, launch) in zip(UIColor(Theme.felt).rgba, asset.rgba) {
            XCTAssertEqual(board, launch, accuracy: Self.componentAccuracy)
        }
    }
}

extension UIColor {
    /// The colour's sRGB components, for comparing colours from different sources.
    var rgba: [CGFloat] {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return [red, green, blue, alpha]
    }
}
