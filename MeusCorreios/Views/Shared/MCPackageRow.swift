import SwiftUI

struct MCPackageRow: View {
    let package: MCPackage
    let isLoading: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(package.displayName)
                    .font(.headline)
                if package.displayName != package.id {
                    Text(package.id)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let status = package.currentStatus {
                    Label(status.rawValue, systemImage: status.systemImage)
                        .font(.subheadline)
                        .foregroundStyle(status.color)
                }
            }
            Spacer()
            if isLoading {
                ProgressView()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        MCPackageRow(
            package: MCPackage(
                id: "AA123456789BR",
                nickname: "Tênis novo",
                events: [MCTrackingEvent(date: .now, location: "Rio de Janeiro/RJ", status: .saiuParaEntrega, description: "Objeto saiu para entrega")]
            ),
            isLoading: false
        )
    }
}
