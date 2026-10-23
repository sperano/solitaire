import SwiftUI

/// Shows `front` or `back`, turning about the vertical axis when `isFaceUp` changes inside an
/// animated transaction; the side swaps halfway, when the card is edge-on.
struct FlipView<Front: View, Back: View>: View, @MainActor Animatable {
    private static var halfTurn: Double { 180 }
    private static var quarterTurn: Double { 90 }

    /// 0 when the front faces the player, 180 when the back does.
    var angle: Double
    let front: Front
    let back: Back

    init(isFaceUp: Bool, @ViewBuilder front: () -> Front, @ViewBuilder back: () -> Back) {
        angle = isFaceUp ? 0 : Self.halfTurn
        self.front = front()
        self.back = back()
    }

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        // Only the side facing the player is drawn, so a face-down card has no hidden glyphs.
        Group {
            if angle < Self.quarterTurn {
                front
            } else {
                // Pre-rotated so it reads the right way round once the whole card has turned.
                back.rotation3DEffect(.degrees(Self.halfTurn), axis: (x: 0, y: 1, z: 0))
            }
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0))
    }
}
