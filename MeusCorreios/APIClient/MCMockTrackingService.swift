import Foundation

/// Implementação provisória enquanto não integramos a API real dos Correios.
/// Gera uma linha do tempo determinística a partir do código, para que o mesmo
/// código sempre produza o mesmo resultado durante o desenvolvimento.
struct MCMockTrackingService: MCTrackingServicing {
    private static let timeline: [(status: MCTrackingStatus, location: String, description: String)] = [
        (.postado, "São Paulo/SP", "Objeto postado"),
        (.emTransito, "Curitiba/PR", "Objeto em trânsito para unidade de distribuição"),
        (.naUnidade, "Rio de Janeiro/RJ", "Objeto na unidade de distribuição"),
        (.saiuParaEntrega, "Rio de Janeiro/RJ", "Objeto saiu para entrega ao destinatário"),
        (.entregue, "Rio de Janeiro/RJ", "Objeto entregue ao destinatário")
    ]

    func trackPackage(code: String) async throws -> MCPackage {
        let normalized = MCTrackingCode.normalize(code)
        guard MCTrackingCode.isValid(normalized) else {
            throw MCTrackingError.invalidCode
        }

        try await Task.sleep(nanoseconds: 500_000_000)

        let seed = normalized.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let stepCount = 2 + (seed % (Self.timeline.count - 1))
        let now = Date()
        let calendar = Calendar.current

        let events = Self.timeline.prefix(stepCount).enumerated().map { index, step -> MCTrackingEvent in
            let daysAgo = stepCount - index
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            return MCTrackingEvent(date: date, location: step.location, status: step.status, description: step.description)
        }

        return MCPackage(id: normalized, nickname: "", events: events)
    }
}
