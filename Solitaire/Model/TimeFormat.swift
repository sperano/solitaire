/// Shared formatting for game durations.
enum TimeFormat {
    private static let secondsPerMinute = 60

    /// `m:ss`, e.g. `1:05`; minutes keep growing past an hour.
    static func minutesAndSeconds(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / secondsPerMinute
        let seconds = totalSeconds % secondsPerMinute
        return "\(minutes):" + (seconds < 10 ? "0\(seconds)" : "\(seconds)")
    }
}
