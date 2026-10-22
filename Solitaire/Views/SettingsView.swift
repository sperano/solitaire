import SolitaireKit
import SwiftUI

struct SettingsView: View {
    @Bindable var settings: GameSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Draw", selection: $settings.drawMode) {
                        ForEach(DrawMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("drawModePicker")
                } header: {
                    Text("Rules")
                } footer: {
                    Text("Takes effect on the next game.")
                }
                Section("About") {
                    LabeledContent("Version", value: Bundle.main.shortVersion)
                    Text("Free, no ads, no tracking, no account.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
                    .accessibilityIdentifier("settingsDoneButton")
            }
        }
    }
}

extension Bundle {
    var shortVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }
}
