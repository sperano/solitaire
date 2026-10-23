import SwiftUI
import UIKit

extension View {
    /// Section headers in primary rather than the system grey, which the contrast audit flags.
    func formHeader() -> some View {
        foregroundStyle(.primary)
    }

    /// Section footers in `Theme.formFooter`, for the same reason.
    func formFooter() -> some View {
        foregroundStyle(Theme.formFooter)
    }
}

extension Theme {
    /// Destructive button text: the system red is 3.6:1 on white, so light mode uses a darker red.
    static let destructiveText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? .systemRed : UIColor(red: 0.75, green: 0, blue: 0, alpha: 1)
    })
}
