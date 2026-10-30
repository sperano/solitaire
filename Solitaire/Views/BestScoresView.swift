import SolitaireKit
import SwiftUI

/// The highest standard-scored wins for one statistics scope, best first, with a reset that asks first.
struct BestScoresView: View {
    let statistics: StatisticsModel
    let scope: StatisticsView.Scope
    @State private var isConfirmingReset = false

    private var scores: [BestScore] {
        switch scope {
        case .overall: statistics.bestScores.overall
        case let .draw(mode): statistics.bestScores[mode]
        }
    }

    /// The scope is in the title: a section header at the top of the form fails the contrast audit
    /// the way the "Rules" header does in Settings.
    private var title: String {
        switch scope {
        case .overall: String(localized: "Best Scores")
        case let .draw(mode): String(localized: "Best Scores, \(mode.title)", comment: "Best scores of one draw mode")
        }
    }

    var body: some View {
        Form {
            Section {
                if scores.isEmpty {
                    Text("No standard-scored wins yet.")
                        .accessibilityIdentifier("bestScoresEmptyLabel")
                } else {
                    ForEach(Array(scores.enumerated()), id: \.offset) { index, score in
                        BestScoreRow(rank: index + 1, score: score, showsDrawMode: scope == .overall)
                    }
                }
            } footer: {
                Text("Only wins with standard scoring are ranked: every Vegas win pays the same.").formFooter()
            }
            Section {
                Button(role: .destructive) { isConfirmingReset = true } label: {
                    Text("Reset Best Scores").foregroundStyle(Theme.destructiveText)
                }
                .accessibilityIdentifier("resetBestScoresButton")
            }
        }
        .navigationTitle(title)
        .confirmationDialog("Reset all best scores?", isPresented: $isConfirmingReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { statistics.resetBestScores() }
                .accessibilityIdentifier("confirmResetBestScoresButton")
        } message: {
            Text("Every draw mode’s table is emptied. Statistics are kept. This cannot be undone.")
        }
    }
}

/// One ranked win: the rank and score, then when it was won and how.
private struct BestScoreRow: View {
    let rank: Int
    let score: BestScore
    let showsDrawMode: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(verbatim: "\(rank).")
                .font(.headline.monospacedDigit())
            VStack(alignment: .leading) {
                Text(CountPhrase.points(score.score))
                    .font(.headline)
                Text(details)
                    .font(.subheadline)
                    .formFooter()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("bestScore-\(rank)")
    }

    /// The date, the draw mode on the combined table, the time when timed, the moves and the deal.
    private var details: String {
        let date = Date(timeIntervalSince1970: TimeInterval(score.wonAt)).formatted(date: .abbreviated, time: .omitted)
        let moves = CountPhrase.moves(score.moves)
        let deal = String(
            localized: "Deal \(DealNumber.format(score.dealNumber))", comment: "Best scores: the deal number"
        )
        let time = score.seconds.map(TimeFormat.minutesAndSeconds)
        let mode = showsDrawMode ? score.drawMode.title : nil
        return [date, mode, time, moves, deal].compactMap(\.self).joined(separator: " · ")
    }
}
