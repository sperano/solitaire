import SolitaireKit
import SwiftUI

/// The win celebration: every card leaves its foundation in turn, kings first, and bounces off
/// the screen, leaving a short trail. Plays once, behind the "You won!" panel.
struct WinCascadeView: View {
    /// Earlier positions drawn behind each card, every `trailSpacing` steps.
    private static let trailLength = 8
    private static let trailSpacing = 4

    private struct Launch {
        let card: Card
        let start: Double
        let points: [CGPoint]
    }

    private let launches: [Launch]
    private let duration: Double
    private let metrics: BoardMetrics
    @State private var startDate = Date.now
    @State private var isFinished = false

    /// `foundations` are the won foundations, each with its frame on the board.
    init(foundations: [(cards: [Card], frame: CGRect)], bounds: CGRect, metrics: BoardMetrics, delay: Double = 0) {
        let physics = CascadePhysics(bounds: bounds, cardSize: metrics.cardSize)
        let depth = foundations.map(\.cards.count).max() ?? 0
        var launches: [Launch] = []
        for level in 0 ..< depth {
            for (cards, frame) in foundations where level < cards.count {
                let number = launches.count
                launches.append(Launch(
                    card: cards[cards.count - 1 - level],
                    start: delay + CascadePhysics.launchTime(of: number),
                    points: physics.trajectory(launchNumber: number, from: CGPoint(x: frame.midX, y: frame.midY))
                ))
            }
        }
        self.launches = launches
        duration = launches.map { $0.start + Double($0.points.count) * CascadePhysics.timeStep }.max() ?? 0
        self.metrics = metrics
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: isFinished)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)
            Canvas { context, _ in
                for (number, launch) in launches.enumerated() {
                    guard let card = context.resolveSymbol(id: number) else { continue }
                    for point in trail(of: launch, at: elapsed) {
                        context.draw(card, at: point)
                    }
                }
            } symbols: {
                ForEach(Array(launches.enumerated()), id: \.offset) { number, launch in
                    CardView(card: launch.card, metrics: metrics).tag(number)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            // Stop redrawing once every card has left the screen.
            try? await Task.sleep(for: .seconds(duration))
            isFinished = true
        }
    }

    /// The card's current position and the trail behind it, oldest first.
    private func trail(of launch: Launch, at elapsed: Double) -> [CGPoint] {
        let step = Int((elapsed - launch.start) / CascadePhysics.timeStep)
        guard step >= 0, step < launch.points.count else { return [] }
        return stride(from: Self.trailLength - 1, through: 0, by: -1).compactMap { back in
            let index = step - back * Self.trailSpacing
            return index >= 0 ? launch.points[index] : nil
        }
    }
}
