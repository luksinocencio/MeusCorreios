import Foundation

@MainActor
final class MCPackageStore: ObservableObject {
    @Published private(set) var packages: [MCPackage] = []

    private let defaults: UserDefaults
    private let storageKey = "MCPackageStore.packages"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func upsert(_ package: MCPackage) {
        if let index = packages.firstIndex(where: { $0.id == package.id }) {
            packages[index] = package
        } else {
            packages.append(package)
        }
        save()
    }

    func remove(at offsets: IndexSet) {
        packages.remove(atOffsets: offsets)
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([MCPackage].self, from: data) else {
            return
        }
        packages = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(packages) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
