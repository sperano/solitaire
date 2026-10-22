import Foundation
import SolitaireKit

/// Picks the real stores for normal launches and deterministic in-memory ones under UI tests.
@MainActor
struct AppEnvironment {
    static let uiTestingFlag = "--ui-testing"
    static let seedArgument = "-seed"
    static let drawModeArgument = "-drawMode"
    static let scoringModeArgument = "-scoringMode"
    private static let uiTestingDefaultsSuite = "quebec.spe.Solitaire.ui-testing"
    private static let savedGameFileName = "current-game.json"
    private static let statisticsFileName = "statistics.json"

    let store: any GameStore
    let statisticsStore: any StatisticsStore
    let settings: GameSettings
    let fixedSeed: UInt64?

    static var current: AppEnvironment {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains(uiTestingFlag) {
            return uiTesting(arguments: arguments)
        }
        return AppEnvironment(
            store: FileGameStore(url: applicationSupportURL(savedGameFileName)),
            statisticsStore: FileStatisticsStore(url: applicationSupportURL(statisticsFileName)),
            settings: GameSettings(defaults: .standard),
            fixedSeed: nil
        )
    }

    func makeViewModel() -> GameViewModel {
        GameViewModel(
            store: store, settings: settings, statistics: StatisticsModel(store: statisticsStore), fixedSeed: fixedSeed
        )
    }

    private static func uiTesting(arguments: [String]) -> AppEnvironment {
        let defaults = UserDefaults(suiteName: uiTestingDefaultsSuite) ?? .standard
        defaults.removePersistentDomain(forName: uiTestingDefaultsSuite)
        let settings = GameSettings(defaults: defaults)
        if let raw = value(after: drawModeArgument, in: arguments), let mode = Int(raw).flatMap(DrawMode.init(rawValue:)) {
            settings.drawMode = mode
        }
        if let raw = value(after: scoringModeArgument, in: arguments),
           let mode = Int(raw).flatMap(ScoringMode.init(rawValue:)) {
            settings.scoringMode = mode
        }
        let seed = value(after: seedArgument, in: arguments).flatMap { UInt64($0) }
        return AppEnvironment(
            store: InMemoryGameStore(), statisticsStore: InMemoryStatisticsStore(), settings: settings, fixedSeed: seed
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
