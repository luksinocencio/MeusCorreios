import Foundation
import SwiftData

/// Modelos de persistência (SwiftData) para a lista de pacotes acompanhados.
/// `MCPackageStore` converte entre estes registros e o domínio (`MCPackage`/`MCTrackingEvent`),
/// que continua sendo o tipo usado por ViewModels, Views e o APIClient.
@Model
final class MCPackageRecord {
    @Attribute(.unique) var id: String
    var nickname: String
    /// Mantém a ordem em que os pacotes foram adicionados na lista.
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \MCTrackingEventRecord.package)
    var events: [MCTrackingEventRecord] = []

    init(id: String, nickname: String, createdAt: Date = .now) {
        self.id = id
        self.nickname = nickname
        self.createdAt = createdAt
    }
}

@Model
final class MCTrackingEventRecord {
    var id: UUID
    var date: Date
    var location: String
    var status: MCTrackingStatus
    var eventDescription: String
    var package: MCPackageRecord?

    init(id: UUID, date: Date, location: String, status: MCTrackingStatus, eventDescription: String) {
        self.id = id
        self.date = date
        self.location = location
        self.status = status
        self.eventDescription = eventDescription
    }

    convenience init(_ event: MCTrackingEvent) {
        self.init(id: event.id, date: event.date, location: event.location, status: event.status, eventDescription: event.description)
    }
}

extension MCTrackingEventRecord {
    /// A API Rastro não envia um id por evento, então a identidade é a chave natural
    /// data + local + descrição. `MCPackageStore` usa isso para reaproveitar registros
    /// já salvos a cada atualização, em vez de apagar e recriar toda a linha do tempo.
    var matchKey: String {
        Self.matchKey(date: date, location: location, description: eventDescription)
    }

    static func matchKey(date: Date, location: String, description: String) -> String {
        "\(date.timeIntervalSince1970)|\(location)|\(description)"
    }
}

extension MCTrackingEvent {
    var matchKey: String {
        MCTrackingEventRecord.matchKey(date: date, location: location, description: description)
    }
}

extension MCPackageRecord {
    var asPackage: MCPackage {
        MCPackage(
            id: id,
            nickname: nickname,
            events: events
                .map { MCTrackingEvent(id: $0.id, date: $0.date, location: $0.location, status: $0.status, description: $0.eventDescription) }
                .sorted { $0.date < $1.date }
        )
    }
}
