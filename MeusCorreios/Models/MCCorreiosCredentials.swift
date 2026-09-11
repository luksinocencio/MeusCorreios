import Foundation

enum MCCorreiosEnvironment: String, Codable, CaseIterable, Identifiable, Hashable {
    case producao
    case homologacao

    var id: String { rawValue }

    var title: String {
        switch self {
        case .producao: "Produção"
        case .homologacao: "Homologação"
        }
    }

    var baseURL: URL {
        switch self {
        case .producao: URL(string: "https://api.correios.com.br")!
        case .homologacao: URL(string: "https://apihom.correios.com.br")!
        }
    }
}

/// Credenciais da API dos Correios (Meu Correios + contrato/cartão de postagem).
/// Persistidas no Keychain por `MCCredentialsStore` — nunca em UserDefaults.
struct MCCorreiosCredentials: Codable, Equatable {
    enum AuthMode: String, Codable, CaseIterable, Identifiable, Hashable {
        case simples
        case contrato
        case cartaoPostagem

        var id: String { rawValue }

        var title: String {
            switch self {
            case .simples: "Usuário e senha"
            case .contrato: "Usuário, senha e contrato"
            case .cartaoPostagem: "Usuário, senha e cartão de postagem"
            }
        }
    }

    var environment: MCCorreiosEnvironment = .producao
    var authMode: AuthMode = .simples
    var usuario: String = ""
    var senha: String = ""
    var numeroContrato: String = ""
    var numeroCartaoPostagem: String = ""
    var dr: String = ""

    var isComplete: Bool {
        guard !usuario.isEmpty, !senha.isEmpty else { return false }
        switch authMode {
        case .simples:
            return true
        case .contrato:
            return !numeroContrato.isEmpty && !dr.isEmpty
        case .cartaoPostagem:
            return !numeroCartaoPostagem.isEmpty && !numeroContrato.isEmpty && !dr.isEmpty
        }
    }
}
