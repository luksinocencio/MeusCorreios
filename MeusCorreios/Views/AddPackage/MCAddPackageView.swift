import SwiftUI

struct MCAddPackageView: View {
    @ObservedObject var viewModel: MCPackageListViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var nickname = ""
    @State private var isSaving = false

    private var isValid: Bool {
        MCTrackingCode.isValid(code)
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
                            await viewModel.add(code: code, nickname: nickname)
                            isSaving = false
                            if viewModel.errorMessage == nil {
                                dismiss()
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
        }
    }
}

#Preview {
    MCAddPackageView(viewModel: MCPackageListViewModel(store: .inMemory(), service: MCMockTrackingService()))
}
