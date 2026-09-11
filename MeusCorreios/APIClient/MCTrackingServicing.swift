import Foundation

protocol MCTrackingServicing {
    func trackPackage(code: String) async throws -> MCPackage
}

enum MCTrackingError: LocalizedError {
    case invalidCode
    case notFound
    case missingCredentials
    case authenticationFailed
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "Código de rastreio inválido. Use o formato AA123456789BR."
        case .notFound:
            return "Não encontramos informações para esse código."
        case .missingCredentials:
            return "Configure suas credenciais da API dos Correios em Ajustes."
        case .authenticationFailed:
            return "Não foi possível autenticar na API dos Correios. Confira usuário, senha e dados do contrato em Ajustes."
        case .requestFailed:
            return "Falha ao consultar o rastreamento. Tente novamente em instantes."
        }
    }
}
