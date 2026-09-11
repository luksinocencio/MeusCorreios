import Foundation

/// Converte as datas do formato retornado pela API Rastro dos Correios
/// ("yyyy-MM-dd'T'HH:mm:ss", sem timezone, horário de Brasília).
enum MCCorreiosDateFormatter {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "America/Sao_Paulo")
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter
    }()

    static func parse(_ string: String) -> Date? {
        formatter.date(from: string)
    }
}
