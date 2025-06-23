import SwiftUI

// MARK: - Custom Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    let color: Color
    var textColor: Color?
    let isLoading: Bool
    
    init(color: Color = .blue, textColor: Color? = nil, isLoading: Bool = false) {
        self.color = color
        self.textColor = textColor
        self.isLoading = isLoading
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(textColor ?? .white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(configuration.isPressed ? 0.8 : 1.0))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .disabled(isLoading)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Progress View with Gradient

struct GradientProgressView: View {
    let value: Double
    let total: Double
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(value / total, 1.0)
    }
    
    private var gradientColors: [Color] {
        [
            Color(red: 216/255, green: 122/255, blue: 239/255), // Left color
            Color(red: 191/255, green: 93/255, blue: 93/255)    // Right color
        ]
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                // Progress fill with gradient
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
        }
        .frame(height: 8)
    }
}
