import SwiftUI

/// Tema da interface escolhido em Ajustes. Persistido em `UserDefaults` via `@AppStorage`
/// e aplicado na raiz da hierarquia (`MCApp`) com `.preferredColorScheme`.
enum MCAppearance: String, CaseIterable, Identifiable {
    case sistema
    case claro
    case escuro

    static let storageKey = "MCAppearance.selected"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sistema: "Sistema"
        case .claro: "Claro"
        case .escuro: "Escuro"
        }
    }

    /// `nil` acompanha a aparência do sistema.
    var colorScheme: ColorScheme? {
        switch self {
        case .sistema: nil
        case .claro: .light
        case .escuro: .dark
        }
    }
}
