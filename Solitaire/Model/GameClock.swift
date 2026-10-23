/// The clock the game timer runs on, so tests can drive time by hand.
protocol GameClock: Sendable {
    /// Time since an origin of the clock's choosing; only differences matter.
    var now: Duration { get }
    func sleep(for duration: Duration) async throws
}

/// The real clock, which keeps counting while the device sleeps.
struct SystemGameClock: GameClock {
    private let origin = ContinuousClock.now

    var now: Duration { origin.duration(to: ContinuousClock.now) }

    func sleep(for duration: Duration) async throws {
        try await ContinuousClock().sleep(for: duration)
    }
}
