import Foundation
import OSLog

/// Reads and writes one `Codable` value as a JSON file. Best effort: a failed read returns nil
/// and a failed write is logged, so a damaged file never stops the game.
@MainActor
struct JSONFileStorage<Value: Codable> {
    private static var logger: Logger { Logger(subsystem: "quebec.spe.Solitaire", category: "Storage") }

    let url: URL

    /// The stored value, or nil when there is none or it cannot be read.
    func load() -> Value? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try JSONDecoder().decode(Value.self, from: data)
        } catch {
            Self.logger.error("Discarding unreadable \(url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Writes `value`, or deletes the file when it is nil.
    func save(_ value: Value?) {
        do {
            guard let value else {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
                return
            }
            let data = try JSONEncoder().encode(value)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
        } catch {
            Self.logger.error("Could not save \(url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }
}
