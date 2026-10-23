import UIKit

/// What the player feels.
enum HapticEvent: Equatable {
    case move
    /// A drop, tap or draw that the rules refuse.
    case invalidMove
    case win
}

@MainActor
protocol HapticPlayer {
    func play(_ event: HapticEvent)
}

/// The device's Taptic Engine.
@MainActor
final class SystemHaptics: HapticPlayer {
    private let impact = UIImpactFeedbackGenerator(style: .light)
    private let notification = UINotificationFeedbackGenerator()

    func play(_ event: HapticEvent) {
        switch event {
        case .move: impact.impactOccurred()
        case .invalidMove: notification.notificationOccurred(.error)
        case .win: notification.notificationOccurred(.success)
        }
    }
}

/// Plays nothing; for previews and tests that don't check haptics.
@MainActor
final class SilentHaptics: HapticPlayer {
    func play(_ event: HapticEvent) {}
}
