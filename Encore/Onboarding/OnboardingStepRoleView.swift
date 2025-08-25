import SwiftUI

struct OnboardingStepRoleView: View {

    // MARK: - Properties
    
    @Binding var selectedRole: UserRole?
    let onContinue: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text("Welcome to Encore")
                    .font(.largeTitle.bold())
                
                Text("To get started, please tell us your primary role.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Role Selection Cards
            VStack(spacing: 16) {
                roleCard(
                    role: .artist,
                    iconName: "music.mic",
                    description: "For solo artists and band members managing their own tours."
                )
                roleCard(
                    role: .manager,
                    iconName: "person.badge.key.fill",
                    description: "For artist managers handling logistics for one or more acts."
                )
                roleCard(
                    role: .agency,
                    iconName: "building.2.fill",
                    description: "For agencies and labels managing a roster of touring artists."
                )
            }
            
            Spacer()
            
            // Continue Button
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedRole == nil ? Color.gray : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(selectedRole == nil)
        }
        .padding(32)
    }
    
    // MARK: - Subviews
    
    /// A tappable card view for a single role option.
    private func roleCard(role: UserRole, iconName: String, description: String) -> some View {
        let isSelected = selectedRole == role
        
        return Button(action: {
            withAnimation {
                selectedRole = role
            }
        }) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.largeTitle)
                    .foregroundColor(isSelected ? .accentColor : .primary)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(role.rawValue)
                        .font(.title2.bold())
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
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
