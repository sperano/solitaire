import Foundation
@testable import Solitaire

/// A clock tests move by hand: `now` only changes through `advance(by:)`, which wakes every
/// sleeper whose deadline has passed and lets the woken tasks run until they sleep again.
final class TestClock: GameClock, @unchecked Sendable {
    /// The most yields spent waiting for tasks to reach their sleep; a woken task that ends
    /// instead (its timer was stopped) never registers again, so the wait must be bounded.
    private static let maxYields = 500

    private struct Sleeper {
        let id: UUID
        let deadline: Duration
        let continuation: CheckedContinuation<Void, any Error>
    }

    private let lock = NSLock()
    private var current = Duration.zero
    private var sleepers: [Sleeper] = []

    var now: Duration { lock.withLock { current } }

    /// How many tasks are sleeping on the clock, which tells whether the timer is ticking.
    var sleeperCount: Int { lock.withLock { sleepers.count } }

    func sleep(for duration: Duration) async throws {
        let id = UUID()
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                lock.withLock { sleepers.append(Sleeper(id: id, deadline: current + duration, continuation: continuation)) }
            }
        } onCancel: {
            remove(id)?.continuation.resume(throwing: CancellationError())
        }
    }

    /// Yields until a task started by the code under test reaches its sleep.
    func waitForSleeper() async {
        await yield(until: { self.sleeperCount > 0 })
    }

    func advance(by duration: Duration) async {
        let (total, due) = lock.withLock {
            current += duration
            let total = sleepers.count
            let (due, waiting) = sleepers.reduce(into: ([Sleeper](), [Sleeper]())) { result, sleeper in
                if sleeper.deadline <= current { result.0.append(sleeper) } else { result.1.append(sleeper) }
            }
            sleepers = waiting
            return (total, due)
        }
        for sleeper in due.sorted(by: { $0.deadline < $1.deadline }) { sleeper.continuation.resume() }
        // Woken tasks run until they sleep again, or finish.
        await yield(until: { self.sleeperCount >= total })
    }

    private func yield(until done: () -> Bool) async {
        for _ in 0 ..< Self.maxYields where !done() { await Task.yield() }
    }

    private func remove(_ id: UUID) -> Sleeper? {
        lock.withLock {
            guard let index = sleepers.firstIndex(where: { $0.id == id }) else { return nil }
            return sleepers.remove(at: index)
        }
    }
}
