import SwiftUI

/// Animations the board plays, dropped when the system's Reduce Motion is on.
enum Motion {
    static func animation(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}
