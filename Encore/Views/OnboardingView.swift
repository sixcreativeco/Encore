import SwiftUI

// Defines a single step in the onboarding tutorial
struct OnboardingStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
}

// The main view for the onboarding tutorial pop-up
struct OnboardingView: View {
    @Binding var isPresented: Bool
    let steps: [OnboardingStep]
    
    @State private var currentStepIndex = 0
    
    // A simple manager to track if the tutorial has been completed
    class OnboardingManager {
        private static let onboardingCompletedKey = "onboardingCompleted"
        
        static func hasCompletedOnboarding() -> Bool {
            return UserDefaults.standard.bool(forKey: onboardingCompletedKey)
        }
        
        static func setOnboardingCompleted() {
            UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
        }
    }

    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: steps[currentStepIndex].iconName)
                    .font(.system(size: 50))
                    .foregroundColor(.accentColor)
                
                Text(steps[currentStepIndex].title)
                    .font(.largeTitle.bold())
                
                Text(steps[currentStepIndex].description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                HStack {
                    if currentStepIndex > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStepIndex -= 1
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if currentStepIndex < steps.count - 1 {
                        Button("Next") {
                            withAnimation {
                                currentStepIndex += 1
                            }
                        }
                    } else {
                        Button("Get Started") {
                            OnboardingManager.setOnboardingCompleted()
                            isPresented = false
                        }
                    }
                }
                .padding(.top)
            }
            .padding(30)
            .background(.regularMaterial)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.4))
        .edgesIgnoringSafeArea(.all)
    }
}
