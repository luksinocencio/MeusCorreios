import SwiftUI

struct MCSettingsView: View {
    @ObservedObject var credentialsStore: MCCredentialsStore
    @AppStorage(MCAppearance.storageKey) private var appearance: MCAppearance = .sistema
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Aparência") {
                    Picker("Tema", selection: $appearance) {
                        ForEach(MCAppearance.allCases) { appearance in
                            Text(appearance.title).tag(appearance)
                        }
                    }
                }

                Section("Ambiente") {
                    Picker("Ambiente", selection: $credentialsStore.credentials.environment) {
                        ForEach(MCCorreiosEnvironment.allCases) { environment in
                            Text(environment.title).tag(environment)
                        }
                    }
                }

                Section("Autenticação") {
                    Picker("Tipo", selection: $credentialsStore.credentials.authMode) {
                        ForEach(MCCorreiosCredentials.AuthMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    TextField("Usuário (Meu Correios)", text: $credentialsStore.credentials.usuario)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Senha do componente", text: $credentialsStore.credentials.senha)
                }

                if credentialsStore.credentials.authMode != .simples {
                    Section("Dados do contrato") {
                        TextField("Número do contrato", text: $credentialsStore.credentials.numeroContrato)
                            .keyboardType(.numberPad)
                        TextField("DR (código regional)", text: $credentialsStore.credentials.dr)
                            .keyboardType(.numberPad)
                        if credentialsStore.credentials.authMode == .cartaoPostagem {
                            TextField("Número do cartão de postagem", text: $credentialsStore.credentials.numeroCartaoPostagem)
                                .keyboardType(.numberPad)
                        }
                    }
                }

                Section {
                    Link("Portal de desenvolvedores dos Correios", destination: URL(string: "https://www.correios.com.br/atendimento/developers")!)
                } footer: {
                    Text("Suas credenciais ficam salvas apenas no Chaveiro deste dispositivo. É necessário ter cadastro no Meu Correios e o serviço Rastro habilitado no seu cartão de postagem.")
                }
            }
            .navigationTitle("Ajustes")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Concluir") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    MCSettingsView(credentialsStore: MCCredentialsStore())
}
