import Foundation

/// Converte as datas devolvidas pela API Rastro dos Correios. O formato
/// documentado é "yyyy-MM-dd'T'HH:mm:ss" (sem timezone, horário de Brasília),
/// mas a API também devolve variações com frações de segundo.
enum MCCorreiosDateFormatter {
    private static let formatters: [DateFormatter] = [
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ss.SSS",
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
    ].map(makeFormatter)

    /// Último recurso, para datas que venham com fuso explícito (ex.: sufixo "Z").
    /// São dois: o ISO8601DateFormatter exige que a fração de segundo esteja
    /// presente quando `.withFractionalSeconds` está ligado, e ausente quando não está.
    private static let isoFormatters: [ISO8601DateFormatter] = {
        let optionSets: [ISO8601DateFormatter.Options] = [
            [.withInternetDateTime],
            [.withInternetDateTime, .withFractionalSeconds]
        ]
        return optionSets.map { options in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = options
            return formatter
        }
    }()

    static func parse(_ string: String) -> Date? {
        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        for formatter in isoFormatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }

    private static func makeFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = TimeZone(identifier: "America/Sao_Paulo")
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter
    }
}
