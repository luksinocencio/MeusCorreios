import Foundation
import OSLog

/// Implementação real: GET /srorastro/v1/objetos/{codigo}?resultado=T na API Rastro dos Correios.
/// https://www.correios.com.br/atendimento/developers
@MainActor
struct MCCorreiosTrackingService: MCTrackingServicing {
    private let session: URLSession
    private let authService: MCCorreiosAuthService
    private let logger = Logger(subsystem: "com.devmeist3r.MeusCorreios", category: "MCCorreiosTrackingService")

    init(session: URLSession = .shared, authService: MCCorreiosAuthService) {
        self.session = session
        self.authService = authService
    }

    func trackPackage(code: String) async throws -> MCPackage {
        let normalized = MCTrackingCode.normalize(code)
        guard MCTrackingCode.isValid(normalized) else {
            throw MCTrackingError.invalidCode
        }

        let (token, baseURL) = try await authService.validToken()

        var components = URLComponents(
            url: baseURL.appendingPathComponent("srorastro/v1/objetos/\(normalized)"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "resultado", value: "T")]

        guard let url = components?.url else {
            throw MCTrackingError.requestFailed
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw MCTrackingError.requestFailed
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MCTrackingError.requestFailed
        }
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            authService.invalidateToken()
            throw MCTrackingError.authenticationFailed
        }
        if httpResponse.statusCode == 404 {
            throw MCTrackingError.notFound
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw MCTrackingError.requestFailed
        }

        guard let decoded = try? JSONDecoder().decode(MCRastroResponse.self, from: data),
              let objeto = decoded.objetos.first else {
            throw MCTrackingError.notFound
        }

        // Sem data confiável não há como posicionar o evento na linha do tempo;
        // inventar uma (antes, `Date()`) o colocaria no topo como se fosse o mais recente.
        let events = objeto.eventos.compactMap { evento -> MCTrackingEvent? in
            guard let date = MCCorreiosDateFormatter.parse(evento.dtHrCriado) else {
                logger.error("Evento ignorado: data em formato inesperado (\(evento.dtHrCriado, privacy: .public))")
                return nil
            }
            let location = [evento.unidade?.endereco?.cidade, evento.unidade?.endereco?.uf]
                .compactMap { $0 }
                .joined(separator: "/")
            let status = MCTrackingStatus.classify(codigo: evento.codigo, descricao: evento.descricao)
            return MCTrackingEvent(date: date, location: location, status: status, description: evento.descricao)
        }

        return MCPackage(id: normalized, nickname: "", events: events)
    }
}
