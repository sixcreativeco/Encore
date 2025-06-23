import SwiftUI

struct ActionButton: View {
    let title: String
    let icon: String?
    let color: Color
    var textColor: Color?
    var isLoading: Bool = false
    let action: () -> Void

    private var isDarkBackground: Bool {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
        NSColor(color).getRed(&red, green: &green, blue: &blue, alpha: nil)
        let brightness = (red * 299 + green * 587 + blue * 114) / 1000
        return brightness < 0.5
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .colorInvert()
                        .scaleEffect(0.8)
                        .frame(width: 16, height: 16)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color)
            .foregroundColor(textColor ?? (isDarkBackground ? .white : .black))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}
