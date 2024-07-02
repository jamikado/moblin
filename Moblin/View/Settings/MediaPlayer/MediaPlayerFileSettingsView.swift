import SwiftUI

struct MediaPlayerFileSettingsView: View {
    @EnvironmentObject var model: Model
    var file: SettingsMediaPlayerFile

    private func submitName(value: String) {
        file.name = value.trim()
        model.store()
        model.objectWillChange.send()
    }

    var body: some View {
        Form {
            Section {
                TextEditNavigationView(
                    title: String(localized: "Name"),
                    value: file.name,
                    onSubmit: submitName,
                    capitalize: true
                )
            }
        }
        .navigationTitle("File")
        .toolbar {
            SettingsToolbar()
        }
    }
}