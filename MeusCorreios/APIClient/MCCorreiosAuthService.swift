import Foundation

/// Gera e armazena em memória o token Bearer da API dos Correios (POST /token/v1/autentica*),
/// reutilizando-o enquanto for válido.
@MainActor
final class MCCorreiosAuthService {
    private struct TokenResponse: Decodable {
        let token: String
        let expiraEm: String
    }

    private let session: URLSession
    private let credentialsStore: MCCredentialsStore

    private var cachedToken: String?
    private var expiresAt: Date?
    /// Credenciais que geraram o token em cache: trocar ambiente, usuário ou
    /// senha precisa forçar uma nova autenticação.
    private var cachedCredentials: MCCorreiosCredentials?

    init(session: URLSession = .shared, credentialsStore: MCCredentialsStore) {
        self.session = session
        self.credentialsStore = credentialsStore
    }

    func validToken() async throws -> (token: String, baseURL: URL) {
        let credentials = credentialsStore.credentials
        guard credentials.isComplete else {
            throw MCTrackingError.missingCredentials
        }

        if let cachedToken, let expiresAt,
           cachedCredentials == credentials,
           expiresAt > Date().addingTimeInterval(30) {
            return (cachedToken, credentials.environment.baseURL)
        }

        let result = try await requestToken(credentials: credentials)
        cachedToken = result.token
        expiresAt = result.expiresAt
        cachedCredentials = credentials
        return (result.token, credentials.environment.baseURL)
    }

    /// Descarta o token em memória. Chamado quando a API recusa o token (401/403),
    /// para a consulta seguinte autenticar de novo em vez de repetir o mesmo erro.
    func invalidateToken() {
        cachedToken = nil
        expiresAt = nil
        cachedCredentials = nil
    }

    private func requestToken(credentials: MCCorreiosCredentials) async throws -> (token: String, expiresAt: Date?) {
        var path = "token/v1/autentica"
        var body: [String: Any] = [:]

        switch credentials.authMode {
        case .simples:
            break
        case .contrato:
            path += "/contrato"
            body = ["numero": credentials.numeroContrato, "dr": Int(credentials.dr) ?? 0]
        case .cartaoPostagem:
            path += "/cartaopostagem"
            body = [
                "numero": credentials.numeroCartaoPostagem,
                "contrato": credentials.numeroContrato,
                "dr": Int(credentials.dr) ?? 0
            ]
        }

        var request = URLRequest(url: credentials.environment.baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        guard let credentialData = "\(credentials.usuario):\(credentials.senha)".data(using: .utf8) else {
            throw MCTrackingError.missingCredentials
        }
        request.setValue("Basic \(credentialData.base64EncodedString())", forHTTPHeaderField: "Authorization")

        if !body.isEmpty {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw MCTrackingError.requestFailed
        }

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw MCTrackingError.authenticationFailed
        }

        guard let decoded = try? JSONDecoder().decode(TokenResponse.self, from: data) else {
            throw MCTrackingError.authenticationFailed
        }

        return (decoded.token, MCCorreiosDateFormatter.parse(decoded.expiraEm))
    }
}
