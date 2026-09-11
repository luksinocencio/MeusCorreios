import SwiftUI

struct MCTrackingEventRow: View {
    let event: MCTrackingEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: event.status.systemImage)
                .foregroundStyle(event.status.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.description)
                    .font(.body)
                Text(event.location)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(event.date, format: .dateTime.day().month().year().hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    List {
        MCTrackingEventRow(
            event: MCTrackingEvent(date: .now, location: "Rio de Janeiro/RJ", status: .entregue, description: "Objeto entregue ao destinatário")
        )
    }
}
