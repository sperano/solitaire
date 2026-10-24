import SolitaireKit
import SwiftUI

/// Results overall or for one draw mode, with a reset that asks first.
struct StatisticsView: View {
    /// Which games the screen summarises.
    enum Scope: Hashable, CaseIterable, Identifiable {
        case overall
        case draw(DrawMode)

        static var allCases: [Scope] { [.overall] + DrawMode.allCases.map(Scope.draw) }

        var id: Self { self }

        var title: String {
            switch self {
            case .overall: String(localized: "All", comment: "Statistics of every draw mode together")
            case let .draw(mode): mode.title
            }
        }
    }

    /// Enough to show a rate below one half percent as non-zero.
    private static let winRateFractionDigits = 0 ... 1

    let statistics: StatisticsModel
    @State private var scope = Scope.overall
    @State private var isConfirmingReset = false

    private var record: StatisticsRecord {
        switch scope {
        case .overall: statistics.statistics.overall
        case let .draw(mode): statistics.statistics[mode]
        }
    }

    var body: some View {
        Form {
            Picker("Games", selection: $scope) {
                ForEach(Scope.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("statisticsScopePicker")
            Section {
                row("Played", "\(record.played)", id: "statsPlayed")
                row("Won", "\(record.won)", id: "statsWon")
                row(
                    "Win rate",
                    record.winRate
                        .map { $0.formatted(.percent.precision(.fractionLength(Self.winRateFractionDigits))) },
                    id: "statsWinRate"
                )
            } header: {
                Text("Games").formHeader()
            }
            Section {
                row("Time", record.bestTimeSeconds.map(TimeFormat.minutesAndSeconds), id: "statsBestTime")
                row("Fewest moves", record.fewestMoves.map(String.init), id: "statsFewestMoves")
            } header: {
                Text("Best").formHeader()
            }
            Section {
                row("Current", "\(record.currentStreak)", id: "statsCurrentStreak")
                row("Longest", "\(record.longestStreak)", id: "statsLongestStreak")
            } header: {
                Text("Streaks").formHeader()
            }
            Section {
                Button(role: .destructive) { isConfirmingReset = true } label: {
                    Text("Reset Statistics").foregroundStyle(Theme.destructiveText)
                }
                .accessibilityIdentifier("resetStatisticsButton")
            }
        }
        .navigationTitle("Statistics")
        .confirmationDialog("Reset all statistics?", isPresented: $isConfirmingReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { statistics.reset() }
                .accessibilityIdentifier("confirmResetStatisticsButton")
        } message: {
            Text("Every draw mode goes back to zero. This cannot be undone.")
        }
    }

    /// A labelled value; nil shows a dash. The identifier carries the value for UI tests.
    private func row(_ title: LocalizedStringKey, _ value: String?, id: String) -> some View {
        LabeledContent(title, value: value ?? "—")
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(title))
            .accessibilityValue(value ?? String(localized: "none", comment: "Statistics: no value yet"))
            .accessibilityIdentifier(id)
    }
}
