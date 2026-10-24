import SwiftUI

@main
struct SolitaireApp: App {
    @State private var viewModel = AppEnvironment.current.makeViewModel()

    var body: some Scene {
        WindowGroup {
            GameView(viewModel: viewModel)
        }
        .commands {
            GameCommands(viewModel: viewModel)
        }
    }
}
