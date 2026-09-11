import SwiftUI

struct MCEmptyStateView: View {
    @Binding var isPresentingAddSheet: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Nenhum pacote")
                .font(.title2.bold())
            Text("Adicione um código de rastreio para acompanhar suas encomendas dos Correios.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Adicionar pacote") {
                isPresentingAddSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    MCEmptyStateView(isPresentingAddSheet: .constant(false))
}
