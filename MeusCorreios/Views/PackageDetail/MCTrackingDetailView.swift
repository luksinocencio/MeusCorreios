import SwiftUI

struct MCTrackingDetailView: View {
    let packageID: String
    @ObservedObject var viewModel: MCPackageListViewModel

    private var package: MCPackage? {
        viewModel.packages.first { $0.id == packageID }
    }

    var body: some View {
        Group {
            if let package {
                List {
                    Section {
                        LabeledContent("Código", value: package.id)
                        if let status = package.currentStatus {
                            Label(status.rawValue, systemImage: status.systemImage)
                                .foregroundStyle(status.color)
                        }
                    }

                    Section("Linha do tempo") {
                        ForEach(package.events.sorted(by: { $0.date > $1.date })) { event in
                            MCTrackingEventRow(event: event)
                        }
                    }
                }
                .navigationTitle(package.displayName)
                .refreshable {
                    await viewModel.refresh(package)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Pacote não encontrado")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MCTrackingDetailView(
            packageID: "AA123456789BR",
            viewModel: MCPackageListViewModel(store: .inMemory(), service: MCMockTrackingService())
        )
    }
}
