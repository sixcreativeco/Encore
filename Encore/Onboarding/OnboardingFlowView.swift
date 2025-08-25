import SwiftUI

/// Manages the multi-step onboarding process for new users.
struct OnboardingFlowView: View {
    
    // MARK: - Properties
    
    /// Defines the steps in the onboarding flow with a reliable order.
    private enum OnboardingStep: Int, CaseIterable {
        case role = 0
        case scale = 1
        case goals = 2
        case subscription = 3
    }
    
    // State
    @State private var currentStep: OnboardingStep = .role
    @State private var onboardingData: OnboardingData
    @State private var recommendedPlanID: String = "Indie Artist" // Default recommendation
    
    // Dependencies
    let userID: String
    let onComplete: () -> Void
    
    // Initializer
    init(userID: String, onComplete: @escaping () -> Void) {
        self.userID = userID
        self.onComplete = onComplete
        self._onboardingData = State(initialValue: OnboardingData(userId: userID, goals: []))
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            progressIndicator
            
            Group {
                switch currentStep {
                case .role:
                    OnboardingStepRoleView(
                        selectedRole: $onboardingData.role,
                        onContinue: { navigateTo(.scale) }
                    )
                case .scale:
                    OnboardingStepScaleView(
                        role: onboardingData.role ?? .artist,
                        touringPartySize: $onboardingData.touringPartySize,
                        agencyTeamSize: $onboardingData.agencyTeamSize,
                        agencyRosterSize: $onboardingData.agencyRosterSize,
                        onContinue: { navigateTo(.goals) }
                    )
                case .goals:
                    OnboardingStepGoalsView(
                        selectedGoals: Binding(
                            get: { Set(onboardingData.goals ?? []) },
                            set: { onboardingData.goals = Array($0) }
                        ),
                        onContinue: {
                            determineRecommendation()
                            navigateTo(.subscription)
                        }
                    )
                case .subscription:
                    SubscriptionView(
                        recommendedPlanID: recommendedPlanID,
                        onContinue: { selectedPlan, selectedCycle in
                            onboardingData.selectedPlan = selectedPlan
                            onboardingData.billingCycle = selectedCycle.rawValue
                            saveAndComplete()
                        }
                    )
                }
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // --- FIX: Background changed to match the app's theme ---
        .background(.regularMaterial)
    }
    
    // MARK: - Subviews
    
    private var progressIndicator: some View {
        HStack {
            progressStep(for: .role, label: "Role")
            progressConnector
            progressStep(for: .scale, label: "Scale")
            progressConnector
            progressStep(for: .goals, label: "Goals")
            progressConnector
            progressStep(for: .subscription, label: "Plan")
        }
        .padding(32)
    }
    
    private func progressStep(for step: OnboardingStep, label: String) -> some View {
        // --- FIX: Logic now compares the reliable rawValue integers ---
        let isCompleted = currentStep.rawValue > step.rawValue
        let isCurrent = currentStep == step
        
        return VStack {
            Circle()
                .fill(isCurrent || isCompleted ? Color.accentColor : Color.gray.opacity(0.3))
                .frame(width: 24, height: 24)
            Text(label)
                .font(.caption)
                .foregroundColor(isCurrent || isCompleted ? .primary : .secondary)
        }
    }
    
    private var progressConnector: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 2)
            .padding(.bottom, 24)
    }
    
    // MARK: - Logic
    
    private func navigateTo(_ step: OnboardingStep) {
        withAnimation(.easeInOut) {
            currentStep = step
        }
    }
    
    private func determineRecommendation() {
        guard let role = onboardingData.role else {
            recommendedPlanID = "Indie Artist"
            return
        }
        
        switch role {
        case .artist, .manager:
            if onboardingData.touringPartySize == .sixToFifteen || onboardingData.touringPartySize == .sixteenPlus {
                recommendedPlanID = "Artist Pro"
            } else {
                recommendedPlanID = "Indie Artist"
            }
        case .agency:
            if onboardingData.agencyRosterSize == .elevenToTwentyFive || onboardingData.agencyRosterSize == .twentySixPlus {
                recommendedPlanID = "Agency Pro"
            } else {
                recommendedPlanID = "Indie Agency"
            }
        }
    }
    
    private func saveAndComplete() {
        print("💾 [OnboardingFlowView DEBUG] Saving onboarding data for user \(userID)...")
        FirebaseUserService.shared.saveOnboardingData(onboardingData, for: userID) { error in
            if let error = error {
                print("❌ [OnboardingFlowView DEBUG] Failed to save onboarding data: \(error.localizedDescription)")
            } else {
                print("✅ [OnboardingFlowView DEBUG] Successfully saved onboarding data.")
            }
            onComplete()
        }
    }
}
