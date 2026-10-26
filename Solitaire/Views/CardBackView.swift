import SwiftUI

/// The back of a card in the chosen design (`CardStyle.back`): its colour, a white frame, and the
/// design's pattern inside the frame.
struct CardBackView: View {
    private static let frameInsetRatio: CGFloat = 0.1
    private static let frameWidth: CGFloat = 1.5
    /// The second frame of the double-frame design, further in.
    private static let innerFrameInsetRatio: CGFloat = 0.2
    /// Distance between the lattice's parallel lines.
    private static let latticeSpacingRatio: CGFloat = 0.16
    private static let latticeLineWidth: CGFloat = 1
    private static let latticeOpacity = 0.55

    let metrics: BoardMetrics
    @Environment(\.cardStyle) private var style

    var body: some View {
        ZStack {
            shape.fill(style.back.color)
            pattern
            shape.strokeBorder(style.border, lineWidth: style.borderWidth)
            frame(insetRatio: Self.frameInsetRatio)
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
    }

    private func frame(insetRatio: CGFloat) -> some View {
        shape.inset(by: metrics.cardWidth * insetRatio).strokeBorder(style.backInner, lineWidth: Self.frameWidth)
    }

    @ViewBuilder
    private var pattern: some View {
        switch style.back.pattern {
        case .plain:
            EmptyView()
        case .lattice:
            lattice
                .stroke(style.backInner.opacity(Self.latticeOpacity), lineWidth: Self.latticeLineWidth)
                .clipShape(shape.inset(by: metrics.cardWidth * Self.frameInsetRatio))
        case .doubleFrame:
            frame(insetRatio: Self.innerFrameInsetRatio)
        }
    }

    /// Diagonals both ways across the card, `latticeSpacingRatio` of a card width apart.
    private var lattice: Path {
        let size = metrics.cardSize
        let spacing = metrics.cardWidth * Self.latticeSpacingRatio
        return Path { path in
            var offset = -size.height
            while offset < size.width {
                path.move(to: CGPoint(x: offset, y: 0))
                path.addLine(to: CGPoint(x: offset + size.height, y: size.height))
                path.move(to: CGPoint(x: offset + size.height, y: 0))
                path.addLine(to: CGPoint(x: offset, y: size.height))
                offset += spacing
            }
        }
    }
}
