import Foundation

/// Valida e normaliza códigos de rastreio no formato oficial dos Correios
/// (2 letras + 9 dígitos + 2 letras, ex.: AA123456789BR).
enum MCTrackingCode {
    private static let regex = try! NSRegularExpression(pattern: "^[A-Z]{2}[0-9]{9}[A-Z]{2}$")

    static func normalize(_ rawCode: String) -> String {
        rawCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    static func isValid(_ rawCode: String) -> Bool {
        let code = normalize(rawCode)
        let range = NSRange(code.startIndex..., in: code)
        return regex.firstMatch(in: code, range: range) != nil
    }
}
