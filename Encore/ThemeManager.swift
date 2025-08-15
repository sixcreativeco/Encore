import SwiftUI
import Combine

@MainActor
class ThemeManager: ObservableObject {
    // FIX: The ThemeOption enum is now nested inside the ThemeManager class.
    enum ThemeOption: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { self.rawValue }

        var displayName: String {
            switch self {
            case .system:
                return "System"
            case .light:
                return "Light"
            case .dark:
                return "Dark"
            }
        }
    }
    
    @AppStorage("selectedTheme") private var storedTheme: String = ThemeOption.system.rawValue
    @Published var selectedTheme: ThemeOption = .system
    
    private var cancellable: AnyCancellable?

    init() {
        selectedTheme = ThemeOption(rawValue: storedTheme) ?? .system

        cancellable = $selectedTheme
            .sink { [weak self] newTheme in
                self?.storedTheme = newTheme.rawValue
            }
    }

    var selectedColorScheme: ColorScheme? {
        switch selectedTheme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
