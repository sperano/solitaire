import SolitaireKit
import SwiftUI

struct SettingsView: View {
    @Bindable var settings: GameSettings
    let statistics: StatisticsModel
    /// The deal on the board, for the Deal section.
    let dealNumber: UInt64
    let drawMode: DrawMode
    let isGameStarted: Bool
    let playDeal: (UInt64) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Draw", selection: $settings.drawMode) {
                        ForEach(DrawMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("drawModePicker")
                    Picker("Scoring", selection: $settings.scoringMode) {
                        ForEach(ScoringMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("scoringModePicker")
                    if settings.scoringMode == .vegas {
                        Toggle("Carry balance between games", isOn: $settings.carryVegasBalance)
                            .accessibilityIdentifier("carryVegasBalanceToggle")
                    }
                    Toggle("Winnable deals only", isOn: $settings.winnableDealsOnly)
                        .accessibilityIdentifier("winnableDealsOnlyToggle")
                } header: {
                    Text("Rules").formHeader()
                } footer: {
                    Text(rulesFooter).formFooter()
                }
                Section {
                    Toggle("Finish automatically", isOn: $settings.autoFinish)
                        .accessibilityIdentifier("autoFinishToggle")
                    Toggle("Haptics", isOn: $settings.haptics)
                        .accessibilityIdentifier("hapticsToggle")
                } header: {
                    Text("Play").formHeader()
                } footer: {
                    Text("Once every remaining card can go to the foundations, play them without tapping Finish.").formFooter()
                }
                Section {
                    Toggle("Four-colour deck", isOn: $settings.fourColorDeck)
                        .accessibilityIdentifier("fourColorDeckToggle")
                } header: {
                    Text("Cards").formHeader()
                } footer: {
                    Text("Diamonds blue and clubs green, so no two suits share a colour.").formFooter()
                }
                Section {
                    NavigationLink("Statistics") { StatisticsView(statistics: statistics) }
                        .accessibilityIdentifier("statisticsLink")
                }
                // Below Statistics, which UI tests reach without scrolling.
                DealSection(dealNumber: dealNumber, drawMode: drawMode, isGameStarted: isGameStarted, playDeal: playDeal)
                Section {
                    LabeledContent("Version", value: Bundle.main.shortVersion)
                    Text("Free, no ads, no tracking, no account.")
                } header: {
                    Text("About").formHeader()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
                    .accessibilityIdentifier("settingsDoneButton")
            }
        }
    }
}

private extension SettingsView {
    var rulesFooter: String {
        var sentences: [String] = []
        if settings.scoringMode == .vegas {
            let passes = Scoring.vegasPasses(drawMode: settings.drawMode)
            sentences.append(
                "Vegas: each game costs $\(Scoring.vegasBuyIn), each card on a foundation pays "
                    + "$\(Scoring.vegasPointsPerFoundationCard) (taken back if it leaves), "
                    + "and \(settings.drawMode.title) allows "
                    + "\(passes) \(passes == 1 ? "pass" : "passes") through the stock."
            )
        }
        if settings.winnableDealsOnly {
            sentences.append("New games are dealt until the solver finds a way to win one; a deal number you enter is played as it is.")
        }
        sentences.append("Changes take effect on the next game.")
        return sentences.joined(separator: " ")
    }
}

extension Bundle {
    var shortVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }
}
