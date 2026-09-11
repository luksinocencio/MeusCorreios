import Foundation

@MainActor
final class MCCredentialsStore: ObservableObject {
    /// Cada tecla digitada em Ajustes altera este valor, então a gravação é
    /// adiada: sem isso, cada caractere custaria um delete + add no Chaveiro.
    @Published var credentials: MCCorreiosCredentials {
        didSet { scheduleSave() }
    }

    private let account = "correios-api"
    private let saveDelay: Duration = .milliseconds(500)
    private var saveTask: Task<Void, Never>?

    init() {
        if let data = MCKeychainStore.load(account: account),
           let decoded = try? JSONDecoder().decode(MCCorreiosCredentials.self, from: data) {
            credentials = decoded
        } else {
            credentials = MCCorreiosCredentials()
        }
    }

    /// Grava agora o que estiver pendente. Chamado ao fechar os Ajustes, para
    /// nada se perder caso o app seja encerrado dentro da janela do debounce.
    func saveNow() {
        saveTask?.cancel()
        saveTask = nil
        guard let data = try? JSONEncoder().encode(credentials) else { return }
        MCKeychainStore.save(data, account: account)
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self, saveDelay] in
            try? await Task.sleep(for: saveDelay)
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }
}
