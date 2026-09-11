import Foundation

extension MCTrackingStatus {
    /// A API Rastro tem dezenas de códigos de evento; classificamos pela descrição
    /// (sempre exibida ao usuário na íntegra) para escolher ícone/cor de resumo.
    static func classify(codigo: String, descricao: String) -> MCTrackingStatus {
        let text = descricao
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "pt_BR"))
            .lowercased()

        // A falha vem antes do sucesso: "nao entregue" contém "entregue",
        // então testar a entrega primeiro classificaria a falha como sucesso.
        if text.contains("nao entregue") || text.contains("tentativa") || text.contains("ausente") || text.contains("extraviado") || text.contains("avaria") {
            return .fracassado
        }
        if text.contains("entregue") {
            return .entregue
        }
        if text.contains("saiu para entrega") || text.contains("rota de entrega") {
            return .saiuParaEntrega
        }
        if text.contains("postado") || text.contains("recebido pelos correios") {
            return .postado
        }
        if text.contains("unidade de distribuicao") || text.contains("aguardando retirada") || text.contains("chegou") {
            return .naUnidade
        }
        return .emTransito
    }
}
