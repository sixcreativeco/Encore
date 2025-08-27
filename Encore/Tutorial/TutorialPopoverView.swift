import SwiftUI

/// A view that displays a single tutorial tip in a pop-up bubble with an arrow.
struct TutorialPopoverView: View {
    
    // MARK: - Properties
    
    let step: TutorialStep
    @Binding var dontShowAgain: Bool
    let onBack: () -> Void
    let onNext: () -> Void
    let onFinish: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(step.title)
                    .font(.headline).fontWeight(.bold)
                Spacer()
                Text("\(step.stepNumber)/\(step.totalSteps)")
                    .font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
            }
            
            Text(step.description)
                .font(.subheadline)
            
            // --- FIX: "Don't Show Again" Checkbox Added ---
            Toggle("Don't show this again", isOn: $dontShowAgain)
                .font(.caption)
                .toggleStyle(.checkbox)

            HStack {
                if step.stepNumber > 1 {
                    Button("Back") { onBack() }
                        .buttonStyle(.plain).foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: {
                    if step.stepNumber == step.totalSteps {
                        onFinish()
                    } else {
                        onNext()
                    }
                }) {
                    Text(step.stepNumber == step.totalSteps ? "Finish Tour" : "Next Tip")
                        .font(.headline).fontWeight(.semibold)
                        .padding(.vertical, 8).padding(.horizontal, 24)
                        .background(Color.accentColor).foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(width: 280)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 20)
        .overlay(alignment: .top) {
            Arrow()
                .fill(.regularMaterial)
                .frame(width: 20, height: 10)
                .offset(y: -10)
        }
    }
}

/// A custom shape that draws an upward-pointing arrow for the popover.
fileprivate struct Arrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
