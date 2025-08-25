import SwiftUI

struct OnboardingStepScaleView: View {
    
    // MARK: - Properties
    
    let role: UserRole
    
    // Bindings for survey answers
    @Binding var touringPartySize: TouringPartySize?
    @Binding var agencyTeamSize: AgencyTeamSize?
    @Binding var agencyRosterSize: AgencyRosterSize?
    
    // Action handler
    let onContinue: () -> Void
    
    /// Determines if the form is complete based on the selected role.
    private var isFormValid: Bool {
        switch role {
        case .artist, .manager:
            return touringPartySize != nil
        case .agency:
            return agencyTeamSize != nil && agencyRosterSize != nil
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text("Tell us about your scale")
                    .font(.largeTitle.bold())
                Text("This helps us understand your needs and recommend the right features.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Conditional Questions
            VStack(spacing: 24) {
                if role == .artist || role == .manager {
                    artistManagerQuestions
                } else if role == .agency {
                    agencyQuestions
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
                    .background(isFormValid ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(!isFormValid)
        }
        .padding(32)
    }
    
    // MARK: - Subviews
    
    private var artistManagerQuestions: some View {
        selectionGroup(
            title: "Typical touring party size?",
            selection: $touringPartySize,
            allCases: TouringPartySize.allCases,
            displayName: { $0.displayName }
        )
    }
    
    private var agencyQuestions: some View {
        VStack(spacing: 24) {
            selectionGroup(
                title: "How large is your agency's team?",
                selection: $agencyTeamSize,
                allCases: AgencyTeamSize.allCases,
                displayName: { $0.displayName }
            )
            selectionGroup(
                title: "How many artists are on your roster?",
                selection: $agencyRosterSize,
                allCases: AgencyRosterSize.allCases,
                displayName: { $0.displayName }
            )
        }
    }
    
    /// A reusable view for a question with a set of tappable options.
    @ViewBuilder
    private func selectionGroup<T: CaseIterable & Hashable>(
        title: String,
        selection: Binding<T?>,
        allCases: T.AllCases,
        // --- FIX IS HERE ---
        // The closure is now marked as @escaping.
        displayName: @escaping (T) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(Array(allCases), id: \.self) { option in
                    let isSelected = selection.wrappedValue == option
                    
                    Button(action: {
                        withAnimation {
                            selection.wrappedValue = option
                        }
                    }) {
                        Text(displayName(option))
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
