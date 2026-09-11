import Foundation

struct MCTrackingEvent: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let date: Date
    let location: String
    let status: MCTrackingStatus
    let description: String

    init(id: UUID = UUID(), date: Date, location: String, status: MCTrackingStatus, description: String) {
        self.id = id
        self.date = date
        self.location = location
        self.status = status
        self.description = description
    }
}

enum MCTrackingStatus: String, Codable, CaseIterable, Hashable {
    case postado = "Postado"
    case emTransito = "Em trânsito"
    case naUnidade = "Na unidade de distribuição"
    case saiuParaEntrega = "Saiu para entrega"
    case entregue = "Entregue"
    case fracassado = "Tentativa de entrega não efetuada"
}
