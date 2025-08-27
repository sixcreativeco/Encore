import SwiftUI

/// A model to hold the content for a single step in the feature tutorial.
fileprivate struct FeatureTutorialStep: Identifiable {
    let id = UUID()
    let videoName: String
    let title: String
    let description: String
}

/// The main view for the video-based feature tutorial pop-up.
struct FeatureTutorialView: View {
    
    // MARK: - Properties
    
    var onFinish: (Bool) -> Void // Updated to pass back the checkbox state
    
    @State private var currentStepIndex = 0
    @State private var dontShowAgain = true // Default to true for this tutorial
    
    private let steps: [FeatureTutorialStep] = [
        FeatureTutorialStep(videoName: "TourCreation", title: "Step 1: Create Your Tour", description: "Start by entering the essential details for your tour, like the name and artist. Uploading a poster helps you visually identify it later."),
        FeatureTutorialStep(videoName: "AddCrew", title: "Step 2: Add Your Crew", description: "Invite your team. Add crew members by email to give them access to the tour's schedule and details."),
        FeatureTutorialStep(videoName: "AddShow", title: "Step 3: Add Your Shows", description: "A tour is a collection of shows. Click the '+' button and search for real-world venues to auto-fill details like the address and timezone."),
        FeatureTutorialStep(videoName: "ShowTimings", title: "Step 4: Build the Daily Schedule", description: "Plan each day with detailed itinerary items. Add everything from load-in times and soundchecks to flights and hotels to keep everyone in sync."),
        FeatureTutorialStep(videoName: "ShowExtras", title: "Step 5: Manage Show Details", description: "Dive into a specific show to manage guest lists, view ticketing stats, or open the live setlist view for on-stage control.")
    ]
    
    private var currentStep: FeatureTutorialStep {
        steps[currentStepIndex]
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 24) {
            VideoPlayerView(fileName: currentStep.videoName)
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(spacing: 8) {
                Text(currentStep.title).font(.title2.bold())
                    .transition(.opacity.combined(with: .move(edge: .top)))
                Text(currentStep.description).font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center).frame(height: 60, alignment: .top)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            .id("text_content_\(currentStepIndex)")
            
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentStepIndex ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            // --- FIX: "Don't Show Again" Checkbox Added ---
            Toggle("Don't show this again", isOn: $dontShowAgain)
                .font(.caption)
                .toggleStyle(.checkbox)
                .padding(.horizontal, 40)
            
            Spacer()
            
            HStack {
                Button("Skip") { onFinish(false) } // Pass false to indicate not to save
                    .buttonStyle(.plain).foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: handleNext) {
                    Text(currentStepIndex == steps.count - 1 ? "Get Started" : "Next")
                        .font(.headline).fontWeight(.bold)
                        .padding(.vertical, 12).padding(.horizontal, 40)
                        .background(Color.accentColor).foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(32)
        .frame(width: 550, height: 650) // Increased height for checkbox
        .background(.regularMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
    
    // MARK: - Logic
    
    private func handleNext() {
        if currentStepIndex < steps.count - 1 {
            withAnimation(.easeInOut) {
                currentStepIndex += 1
            }
        } else {
            // On the last step, call the finish handler with the checkbox state
            onFinish(dontShowAgain)
        }
    }
}
