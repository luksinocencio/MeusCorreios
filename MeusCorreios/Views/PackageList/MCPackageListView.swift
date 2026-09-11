import SwiftUI

struct MCPackageListView: View {
    @StateObject private var viewModel: MCPackageListViewModel
    @State private var isPresentingAddSheet = false
    @State private var isPresentingSettings = false

    init(viewModel: (() -> MCPackageListViewModel)? = nil) {
        _viewModel = StateObject(wrappedValue: (viewModel ?? { MCPackageListViewModel() })())
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.packages.isEmpty {
                    MCEmptyStateView(isPresentingAddSheet: $isPresentingAddSheet)
                } else {
                    List {
                        ForEach(viewModel.packages) { package in
                            NavigationLink(value: package.id) {
                                MCPackageRow(package: package, isLoading: viewModel.isLoading(package))
                            }
                        }
                        .onDelete(perform: viewModel.delete)
                    }
                }
            }
            .navigationTitle("Meus Pacotes")
            .navigationDestination(for: String.self) { packageID in
                MCTrackingDetailView(packageID: packageID, viewModel: viewModel)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingAddSheet = true
                    } label: {
                        Label("Adicionar", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigation) {
                    Button {
                        isPresentingSettings = true
                    } label: {
                        Label("Ajustes", systemImage: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddSheet) {
                MCAddPackageView(viewModel: viewModel)
            }
            .sheet(isPresented: $isPresentingSettings) {
                MCSettingsView(credentialsStore: viewModel.credentialsStore)
            }
            .alert("Ops", isPresented: .constant(viewModel.errorMessage != nil), presenting: viewModel.errorMessage) { _ in
                Button("OK") { viewModel.errorMessage = nil }
            } message: { message in
                Text(message)
            }
        }
    }
}

#Preview {
    MCPackageListView {
        MCPackageListViewModel(store: .inMemory(), service: MCMockTrackingService())
    }
}
