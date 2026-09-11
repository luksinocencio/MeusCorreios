import SwiftData
import SwiftUI

@main
struct MCApp: App {
    @AppStorage(MCAppearance.storageKey) private var appearance: MCAppearance = .sistema

    var body: some Scene {
        WindowGroup {
            MCPackageListView()
                .preferredColorScheme(appearance.colorScheme)
        }
        .modelContainer(MCPackageStore.sharedContainer)
    }
}
