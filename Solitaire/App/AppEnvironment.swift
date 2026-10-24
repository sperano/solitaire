import Foundation
import SolitaireKit

/// Picks the real stores for normal launches and deterministic in-memory ones under UI tests.
@MainActor
struct AppEnvironment {
    static let uiTestingFlag = "--ui-testing"
    static let seedArgument = "-seed"
    static let drawModeArgument = "-drawMode"
    static let scoringModeArgument = "-scoringMode"
    static let winnableDealsOnlyArgument = "-winnableDealsOnly"
    private static let uiTestingDefaultsSuite = "quebec.spe.Solitaire.ui-testing"
    private static let savedGameFileName = "current-game.json"
    private static let statisticsFileName = "statistics.json"
    /// UI-test steps can take longer than a hint normally stays up on a slow CI runner, so under
    /// `--ui-testing` a hint lasts until the next move; unit tests cover the timeout.
    private static let uiTestingHintDuration = Duration.seconds(3_600)

    let store: any GameStore
    /// One instance for the whole app: each `StatisticsModel` saves its full copy of the statistics.
    let statistics: StatisticsModel
    let settings: GameSettings
    let fixedSeed: UInt64?
    var hintDuration = GameViewModel.defaultHintDuration

    static var current: AppEnvironment {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains(uiTestingFlag) {
            return uiTesting(arguments: arguments)
        }
        return AppEnvironment(
            store: FileGameStore(url: applicationSupportURL(savedGameFileName)),
            statistics: StatisticsModel(store: FileStatisticsStore(url: applicationSupportURL(statisticsFileName))),
            settings: GameSettings(defaults: .standard),
            fixedSeed: nil
        )
    }

    func makeViewModel() -> GameViewModel {
        let model = GameViewModel(
            store: store, settings: settings, statistics: statistics, haptics: SystemHaptics(), fixedSeed: fixedSeed
        )
        model.hintDuration = hintDuration
        return model
    }

    private static func uiTesting(arguments: [String]) -> AppEnvironment {
        let defaults = UserDefaults(suiteName: uiTestingDefaultsSuite) ?? .standard
        defaults.removePersistentDomain(forName: uiTestingDefaultsSuite)
        let settings = GameSettings(defaults: defaults)
        if let raw = value(after: drawModeArgument, in: arguments),
           let mode = Int(raw).flatMap(DrawMode.init(rawValue:))
        {
            settings.drawMode = mode
        }
        if let raw = value(after: scoringModeArgument, in: arguments),
           let mode = Int(raw).flatMap(ScoringMode.init(rawValue:))
        {
            settings.scoringMode = mode
        }
        if value(after: winnableDealsOnlyArgument, in: arguments) == "1" {
            settings.winnableDealsOnly = true
        }
        let seed = value(after: seedArgument, in: arguments).flatMap { UInt64($0) }
        let position = value(after: FixturePosition.argument, in: arguments).flatMap(FixturePosition.init(rawValue:))
        let saved = position.map {
            SavedGame(
                game: Game(state: $0.state(drawMode: settings.drawMode, scoringMode: settings.scoringMode)),
                elapsedSeconds: 0
            )
        }
        return AppEnvironment(
            store: InMemoryGameStore(saved: saved),
            statistics: StatisticsModel(store: InMemoryStatisticsStore()),
            settings: settings,
            fixedSeed: seed,
            hintDuration: uiTestingHintDuration
        )
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }

    private static func applicationSupportURL(_ fileName: String) -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return directory.appending(path: fileName)
    }
}
