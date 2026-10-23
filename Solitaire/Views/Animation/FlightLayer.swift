import SolitaireKit
import SwiftUI

/// A card on its way between two frames on the board.
struct ActiveFlight: Identifiable, Equatable {
    let id = UUID()
    let before: Card
    let after: Card
    let from: CGRect
    let to: CGRect
    let delay: TimeInterval
    let duration: TimeInterval

    var cardID: String { after.id }
}

/// Draws the cards in flight above the board; the piles hide them (`cardsInFlight`) until they land.
struct FlightLayer: View {
    let flights: [ActiveFlight]
    let metrics: BoardMetrics
    let landed: (ActiveFlight) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(flights) { flight in
                FlyingCard(flight: flight, metrics: metrics, landed: landed)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.cardsInFlight, [])
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct FlyingCard: View {
    let flight: ActiveFlight
    let metrics: BoardMetrics
    let landed: (ActiveFlight) -> Void
    @State private var hasArrived = false

    var body: some View {
        let frame = hasArrived ? flight.to : flight.from
        CardView(card: hasArrived ? flight.after : flight.before, metrics: metrics)
            .position(x: frame.midX, y: frame.midY)
            .onAppear {
                withAnimation(.easeInOut(duration: flight.duration).delay(flight.delay)) {
                    hasArrived = true
                } completion: {
                    landed(flight)
                }
            }
    }
}

extension EnvironmentValues {
    /// Ids of the cards drawn by `FlightLayer`; their pile views keep them invisible meanwhile.
    @Entry var cardsInFlight: Set<String> = []
}
