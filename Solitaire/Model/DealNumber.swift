import SolitaireKit

/// The seed of a deal as players see it: grouped digits on screen, any digits typed in.
enum DealNumber {
    /// 123456789 as "123,456,789", with the separators of the current locale.
    static func format(_ number: UInt64) -> String {
        number.formatted(.number.grouping(.automatic))
    }

    /// The number typed or pasted, with grouping separators and spaces ignored. Nil unless what is
    /// left is a number in `GameState.dealNumberRange`.
    static func parse(_ text: String) -> UInt64? {
        let digits = text.filter(\.isWholeNumber)
        guard !digits.isEmpty, digits.count <= String(GameState.dealNumberRange.upperBound).count,
              let number = UInt64(digits), GameState.dealNumberRange.contains(number) else { return nil }
        return number
    }

    /// What the share sheet sends: the number and the draw mode it was dealt for.
    static func shareText(_ number: UInt64, drawMode: DrawMode) -> String {
        "Solitaire deal \(format(number)), \(drawMode.title)"
    }
}
