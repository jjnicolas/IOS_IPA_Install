import SwiftUI

@main
struct IPA_InstallApp: App {
    @State private var updater = UpdaterModel()

    var body: some Scene {
        DocumentGroup(viewing: IPADocument.self) { fileConfig in
            ShellOutputView(url: fileConfig.fileURL)
        }
        .defaultSize(width: 450, height: 400)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    updater.checkForUpdates()
                }
                .disabled(!updater.canCheckForUpdates)
            }
        }
        Settings {
            SettingsView()
        }
    }
}
