import SolitaireKit
import SwiftUI

/// The Settings section about deal numbers: the current one, a share button, and a way to play a
/// specific deal.
struct DealSection: View {
    let dealNumber: UInt64
    let drawMode: DrawMode
    /// The game on the board has moves, so playing another deal loses it.
    let isGameStarted: Bool
    /// Deals the number the player typed; the sheet closes first.
    let playDeal: (UInt64) -> Void

    @State private var isEnteringNumber = false
    @State private var enteredText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Section {
            LabeledContent("Deal number", value: DealNumber.format(dealNumber))
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("dealNumberLabel")
                .accessibilityValue(DealNumber.format(dealNumber))
            ShareLink(item: DealNumber.shareText(dealNumber, drawMode: drawMode)) {
                Label("Share this deal", systemImage: "square.and.arrow.up")
            }
            .accessibilityIdentifier("shareDealButton")
            Button("Play a deal number…") {
                enteredText = ""
                isEnteringNumber = true
            }
            .accessibilityIdentifier("playDealButton")
        } header: {
            Text("Deal").formHeader()
        } footer: {
            Text("Every deal has a number. Share it, or enter one to play that deal again.").formFooter()
        }
        .alert("Play a deal number", isPresented: $isEnteringNumber) {
            TextField("Deal number", text: $enteredText)
                .keyboardType(.numberPad)
            // Alert buttons ignore `.disabled`; Play with nothing valid typed just closes the alert.
            Button("Play") { play() }
                .accessibilityIdentifier("confirmPlayDealButton")
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private var alertMessage: String {
        let lowest = DealNumber.format(GameState.dealNumberRange.lowerBound)
        let highest = DealNumber.format(GameState.dealNumberRange.upperBound)
        let range = String(localized: "A number from \(lowest) to \(highest).", comment: "Deal numbers allowed")
        guard isGameStarted else { return range }
        return [range, String(localized: "The current game will be lost.")].joined(separator: " ")
    }

    private func play() {
        guard let number = DealNumber.parse(enteredText) else { return }
        dismiss()
        playDeal(number)
    }
}
