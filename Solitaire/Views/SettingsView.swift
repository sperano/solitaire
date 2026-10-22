import SolitaireKit
import SwiftUI

struct SettingsView: View {
    @Bindable var settings: GameSettings
    let statistics: StatisticsModel
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
                } header: {
                    Text("Rules")
                } footer: {
                    Text(rulesFooter)
                }
                Section {
                    NavigationLink("Statistics") { StatisticsView(statistics: statistics) }
                        .accessibilityIdentifier("statisticsLink")
                }
                Section("About") {
                    LabeledContent("Version", value: Bundle.main.shortVersion)
                    Text("Free, no ads, no tracking, no account.")
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
        let timing = "Changes take effect on the next game."
        guard settings.scoringMode == .vegas else { return timing }
        let passes = Scoring.vegasPasses(drawMode: settings.drawMode)
        return "Vegas: each game costs $\(Scoring.vegasBuyIn), each card on a foundation pays "
            + "$\(Scoring.vegasPointsPerFoundationCard) (taken back if it leaves), "
            + "and \(settings.drawMode.title) allows "
            + "\(passes) \(passes == 1 ? "pass" : "passes") through the stock. \(timing)"
    }
}

extension Bundle {
    var shortVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }
}
