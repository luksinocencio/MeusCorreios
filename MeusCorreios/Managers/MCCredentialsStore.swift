import Foundation

@MainActor
final class MCCredentialsStore: ObservableObject {
    @Published var credentials: MCCorreiosCredentials {
        didSet { save() }
    }

    private let account = "correios-api"

    init() {
        if let data = MCKeychainStore.load(account: account),
           let decoded = try? JSONDecoder().decode(MCCorreiosCredentials.self, from: data) {
            credentials = decoded
        } else {
            credentials = MCCorreiosCredentials()
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(credentials) else { return }
        MCKeychainStore.save(data, account: account)
    }
}
