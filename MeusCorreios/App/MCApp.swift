import SwiftData
import SwiftUI

@main
struct MCApp: App {
    var body: some Scene {
        WindowGroup {
            MCPackageListView()
        }
        .modelContainer(MCPackageStore.sharedContainer)
    }
}
