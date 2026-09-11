import SwiftUI

extension MCTrackingStatus {
    var systemImage: String {
        switch self {
        case .postado: "shippingbox"
        case .emTransito: "shippingbox.and.arrow.backward"
        case .naUnidade: "building.2"
        case .saiuParaEntrega: "bicycle"
        case .entregue: "checkmark.circle.fill"
        case .fracassado: "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .entregue: .green
        case .fracassado: .red
        default: .accentColor
        }
    }
}
