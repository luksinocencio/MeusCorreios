import Foundation
import Combine

@MainActor
final class MCPackageListViewModel: ObservableObject {
    @Published private(set) var packages: [MCPackage] = []
    @Published var errorMessage: String?
    @Published private(set) var loadingIDs: Set<String> = []

    let credentialsStore: MCCredentialsStore

    private let store: MCPackageStore
    private let service: MCTrackingServicing

    init(store: MCPackageStore? = nil, credentialsStore: MCCredentialsStore? = nil, service: MCTrackingServicing? = nil) {
        let store = store ?? MCPackageStore()
        let credentialsStore = credentialsStore ?? MCCredentialsStore()
        self.store = store
        self.credentialsStore = credentialsStore
        self.service = service ?? MCCorreiosTrackingService(authService: MCCorreiosAuthService(credentialsStore: credentialsStore))
        store.$packages.assign(to: &$packages)
    }

    func isLoading(_ package: MCPackage) -> Bool {
        loadingIDs.contains(package.id)
    }

    /// Propaga o erro para quem chamou: a sheet de adicionar apresenta o alerta
    /// por conta própria, para não ser descartada junto com o formulário.
    func add(code: String, nickname: String) async throws {
        try await track(code: code, nickname: nickname)
    }

    func refresh(_ package: MCPackage) async {
        do {
            try await track(code: package.id, nickname: package.nickname)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(at offsets: IndexSet) {
        store.remove(at: offsets)
    }

    private func track(code: String, nickname: String) async throws {
        let normalized = MCTrackingCode.normalize(code)
        loadingIDs.insert(normalized)
        defer { loadingIDs.remove(normalized) }

        var package = try await service.trackPackage(code: normalized)
        package.nickname = nickname
        store.upsert(package)
    }
}
