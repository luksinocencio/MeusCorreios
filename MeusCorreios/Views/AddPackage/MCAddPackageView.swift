import SwiftUI

struct MCAddPackageView: View {
    @ObservedObject var viewModel: MCPackageListViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var nickname = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var isValid: Bool {
        MCTrackingCode.isValid(code)
    }

    private var isPresentingError: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Código de rastreio") {
                    TextField("AA123456789BR", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                Section("Apelido (opcional)") {
                    TextField("Ex.: Tênis novo", text: $nickname)
                }
            }
            .navigationTitle("Adicionar pacote")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            isSaving = true
                            defer { isSaving = false }
                            do {
                                try await viewModel.add(code: code, nickname: nickname)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Salvar")
                        }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .alert("Ops", isPresented: isPresentingError, presenting: errorMessage) { _ in
                Button("OK") { errorMessage = nil }
            } message: { message in
                Text(message)
            }
        }
    }
}

#Preview {
    MCAddPackageView(viewModel: MCPackageListViewModel(store: .inMemory(), service: MCMockTrackingService()))
}
