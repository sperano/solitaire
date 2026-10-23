import SnapshotTesting
import SwiftUI
import XCTest
@testable import Solitaire

/// Renders a view as the snapshot simulator shows it and compares the image with the one recorded
/// in `__Snapshots__` next to the test file. Re-record after a deliberate change to a view (README,
/// "Snapshot tests"). The references are recorded on `deviceName`; on any other simulator the tests
/// skip, since the screen size would not match.
@MainActor
class SnapshotTestCase: XCTestCase {
    /// The simulator the references are recorded on, and the one CI runs these tests on.
    static let deviceName = "iPhone 17"
    /// The share of pixels that must match: antialiasing at text edges can shift a few pixels
    /// between simulator builds.
    static let pixelPrecision: Float = 0.995
    /// How close in colour a differing pixel must still be, so a slightly lighter edge passes.
    static let perceptualPrecision: Float = 0.98

    private static let modes: [(name: String, style: UIUserInterfaceStyle)] = [("light", .light), ("dark", .dark)]

    override func setUp() async throws {
        try await super.setUp()
        let device = UIDevice.current.name
        try XCTSkipUnless(device == Self.deviceName, "snapshots are recorded on \(Self.deviceName), not on \(device)")
    }

    /// Asserts a whole screen, laid out in the host app's window with its safe area, in light and
    /// in dark mode.
    func assertScreen(
        _ view: some View, fileID: StaticString = #fileID, file: StaticString = #filePath,
        testName: String = #function, line: UInt = #line
    ) throws {
        let window = try XCTUnwrap(Self.hostWindow, "the test host has no window")
        let config = ViewImageConfig(
            safeArea: window.safeAreaInsets, size: window.bounds.size,
            traits: UITraitCollection { $0.displayScale = window.traitCollection.displayScale }
        )
        assertLightAndDark(view, layout: .device(config: config), fileID: fileID, file: file, testName: testName, line: line)
    }

    /// Asserts a view at the size it asks for, in light and in dark mode.
    func assertFitted(
        _ view: some View, fileID: StaticString = #fileID, file: StaticString = #filePath,
        testName: String = #function, line: UInt = #line
    ) {
        assertLightAndDark(view, layout: .sizeThatFits, fileID: fileID, file: file, testName: testName, line: line)
    }

    private func assertLightAndDark(
        _ view: some View, layout: SwiftUISnapshotLayout,
        fileID: StaticString, file: StaticString, testName: String, line: UInt
    ) {
        for mode in Self.modes {
            assertSnapshot(
                of: view,
                as: .image(
                    drawHierarchyInKeyWindow: layout.isDevice,
                    precision: Self.pixelPrecision, perceptualPrecision: Self.perceptualPrecision,
                    layout: layout, traits: UITraitCollection { $0.userInterfaceStyle = mode.style }
                ),
                named: mode.name, fileID: fileID, file: file, testName: testName, line: line
            )
        }
    }

    private static var hostWindow: UIWindow? {
        UIApplication.shared.connectedScenes.lazy.compactMap { $0 as? UIWindowScene }.first?.keyWindow
    }
}

private extension SwiftUISnapshotLayout {
    /// Screens are drawn in the host app's window, which glass toolbars and materials need.
    var isDevice: Bool {
        if case .device = self { return true }
        return false
    }
}
