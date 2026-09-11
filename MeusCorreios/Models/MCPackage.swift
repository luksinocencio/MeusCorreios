import Foundation

struct MCPackage: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var nickname: String
    var events: [MCTrackingEvent]

    var currentStatus: MCTrackingStatus? {
        events.max(by: { $0.date < $1.date })?.status
    }

    var displayName: String {
        nickname.isEmpty ? id : nickname
    }
}
