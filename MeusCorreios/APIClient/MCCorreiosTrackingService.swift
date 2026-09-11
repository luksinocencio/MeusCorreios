import Foundation

/// Implementação real: GET /srorastro/v1/objetos/{codigo}?resultado=T na API Rastro dos Correios.
/// https://www.correios.com.br/atendimento/developers
@MainActor
struct MCCorreiosTrackingService: MCTrackingServicing {
    private let session: URLSession
    private let authService: MCCorreiosAuthService

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

        let events = objeto.eventos.map { evento -> MCTrackingEvent in
            let date = MCCorreiosDateFormatter.parse(evento.dtHrCriado) ?? Date()
            let location = [evento.unidade?.endereco?.cidade, evento.unidade?.endereco?.uf]
                .compactMap { $0 }
                .joined(separator: "/")
            let status = MCTrackingStatus.classify(codigo: evento.codigo, descricao: evento.descricao)
            return MCTrackingEvent(date: date, location: location, status: status, description: evento.descricao)
        }

        return MCPackage(id: normalized, nickname: "", events: events)
    }
}
