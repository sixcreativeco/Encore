import SwiftUI

struct ThemeSwitchView: View {
    @Binding var selectedTheme: ThemeManager.ThemeOption

    // This computed property determines which icon to show based on the current theme
    private var currentIcon: String {
        switch selectedTheme {
        case .system:
            return "desktopcomputer"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }

    var body: some View {
        Button(action: cycleTheme) {
            Image(systemName: currentIcon)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .padding(8)
                .background(.thickMaterial.opacity(0.5))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // This function cycles to the next theme in the sequence
    private func cycleTheme() {
        withAnimation {
            switch selectedTheme {
            case .system:
                selectedTheme = .light
            case .light:
                selectedTheme = .dark
            case .dark:
                selectedTheme = .system
            }
        }
    }
}
