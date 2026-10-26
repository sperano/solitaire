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
                    Toggle("Timer", isOn: $settings.timed)
                        .accessibilityIdentifier("timerToggle")
                    Toggle("Finish automatically", isOn: $settings.autoFinish)
                        .accessibilityIdentifier("autoFinishToggle")
                    Toggle("Haptics", isOn: $settings.haptics)
                        .accessibilityIdentifier("hapticsToggle")
                    Toggle("Left-handed layout", isOn: $settings.leftHanded)
                        .accessibilityIdentifier("leftHandedToggle")
                } header: {
                    Text("Play").formHeader()
                } footer: {
                    Text(playFooter).formFooter()
                }
                Section {
                    Toggle("Four-colour deck", isOn: $settings.fourColorDeck)
                        .accessibilityIdentifier("fourColorDeckToggle")
                    Toggle("Large print", isOn: $settings.largePrint)
                        .accessibilityIdentifier("largePrintToggle")
                    Picker("Card back", selection: $settings.cardBack) {
                        ForEach(CardBack.allCases) { Text($0.title).tag($0) }
                    }
                    .accessibilityIdentifier("cardBackPicker")
                    Picker("Table", selection: $settings.felt) {
                        ForEach(TableFelt.allCases) { Text($0.title).tag($0) }
                    }
                    .accessibilityIdentifier("feltPicker")
                } header: {
                    Text("Cards").formHeader()
                } footer: {
                    Text(cardsFooter).formFooter()
                }
                Section {
                    NavigationLink("Statistics") { StatisticsView(statistics: statistics) }
                        .accessibilityIdentifier("statisticsLink")
                }
                // Below Statistics, which UI tests reach without scrolling.
                DealSection(
                    dealNumber: dealNumber,
                    drawMode: drawMode,
                    isGameStarted: isGameStarted,
                    playDeal: playDeal
                )
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
    var playFooter: String {
        let timer = settings.timed
            ? String(localized: "The clock pauses while the app is in the background or Settings are open.")
            : String(localized: "Untimed: no clock, no time bonus and no best time.")
        let finish = String(
            localized: "Finish automatically plays the remaining cards once every one can go to the foundations."
        )
        let leftHanded = String(localized: "Left-handed layout puts the stock and the waste on the right.")
        return [timer, finish, leftHanded].joined(separator: " ")
    }

    var cardsFooter: String {
        [
            String(localized: "Diamonds blue and clubs green, so no two suits share a colour."),
            String(localized: "Large print puts a bigger rank and suit in the corner of each card."),
        ].joined(separator: " ")
    }

    var rulesFooter: String {
        var sentences: [String] = []
        if settings.scoringMode == .vegas {
            let passes = Scoring.vegasPasses(drawMode: settings.drawMode)
            sentences.append(vegasRules(passes: passes))
        }
        if settings.winnableDealsOnly {
            sentences.append(String(localized: """
            New games are dealt until the solver finds a way to win one; \
            a deal number you enter is played as it is.
            """))
        }
        sentences.append(String(localized: "Changes take effect on the next game."))
        return sentences.joined(separator: " ")
    }

    func vegasRules(passes: Int) -> String {
        let buyIn = Scoring.vegasBuyIn, payout = Scoring.vegasPointsPerFoundationCard
        let mode = settings.drawMode.title
        let passCount = String(localized: "\(passes) passes", comment: "Vegas: times the stock can be gone through")
        return String(
            localized: """
            Vegas: each game costs $\(buyIn), each card on a foundation pays $\(payout) \
            (taken back if it leaves), and \(mode) allows \(passCount) through the stock.
            """,
            comment: "Vegas rules: the buy-in, the payout per card, the draw mode, the passes"
        )
    }
}

extension Bundle {
    var shortVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }
}
