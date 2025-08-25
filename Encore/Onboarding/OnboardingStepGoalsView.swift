import SwiftUI

struct OnboardingStepGoalsView: View {
    
    // MARK: - Properties
    
    @Binding var selectedGoals: Set<UserGoal>
    let onContinue: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text("What are your main goals?")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                
                Text("Select all that apply. This will help us tailor your experience.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Goals List
            VStack(spacing: 12) {
                ForEach(UserGoal.allCases) { goal in
                    goalSelectionRow(for: goal)
                }
            }
            
            Spacer()
            
            // Continue Button
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedGoals.isEmpty ? Color.gray : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(selectedGoals.isEmpty)
        }
        .padding(32)
    }
    
    // MARK: - Subviews
    
    /// A tappable row for a single goal option.
    private func goalSelectionRow(for goal: UserGoal) -> some View {
        let isSelected = selectedGoals.contains(goal)
        
        return Button(action: {
            withAnimation {
                if isSelected {
                    selectedGoals.remove(goal)
                } else {
                    selectedGoals.insert(goal)
                }
            }
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                Text(goal.rawValue)
                    .font(.headline)
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
