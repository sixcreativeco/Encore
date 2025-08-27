import SwiftUI

// MARK: - PreferenceKey for Reading View Positions

/// A preference key to store the frames of UI elements tagged for the tutorial.
struct TutorialFramePreferenceKey: PreferenceKey {
    typealias Value = [TutorialStepIdentifier: CGRect]

    static var defaultValue: Value = [:]

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - ViewModifier for Tagging UI Elements

extension View {
    /// A modifier to tag a view with a tutorial identifier and report its frame.
    func tutorialAnchor(id: TutorialStepIdentifier) -> some View {
        self.background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: TutorialFramePreferenceKey.self, value: [id: proxy.frame(in: .global)])
            }
        )
    }
}

// MARK: - Main Tutorial Overlay View

struct TutorialOverlayView<Content: View>: View {
    
    // MARK: - Properties
    
    @Binding var isShowingTutorial: Bool
    let content: Content
    var onFinish: (Bool) -> Void // Updated to receive the checkbox state
    
    // State
    @State private var currentStepIndex = 0
    @State private var viewFrames: [TutorialStepIdentifier: CGRect] = [:]
    @State private var dontShowAgain = true // Default to true for this tutorial
    
    // Tutorial Content Definition
    private let tutorialSteps: [TutorialStep]
    
    init(isShowingTutorial: Binding<Bool>, onFinish: @escaping (Bool) -> Void, @ViewBuilder content: () -> Content) {
        self._isShowingTutorial = isShowingTutorial
        self.onFinish = onFinish
        self.content = content()
        
        self.tutorialSteps = [
            TutorialStep(identifier: .dashboard, title: "Dashboard", description: "Your central hub for what's happening today and an overview of your current tour.", stepNumber: 1, totalSteps: 7),
            TutorialStep(identifier: .tours, title: "Tours", description: "Manage all your past, current, and upcoming tours. Select a tour to see its details.", stepNumber: 2, totalSteps: 7),
            TutorialStep(identifier: .tickets, title: "Tickets", description: "Set up and manage ticket sales for your shows and track your earnings.", stepNumber: 3, totalSteps: 7),
            TutorialStep(identifier: .database, title: "Database", description: "A centralized place for all your contacts, venues, hotels, and customers across all tours.", stepNumber: 4, totalSteps: 7),
            TutorialStep(identifier: .export, title: "Export", description: "Generate professional PDF documents like tour books, day sheets, and guest lists.", stepNumber: 5, totalSteps: 7),
            TutorialStep(identifier: .myAccount, title: "My Account", description: "Manage your subscription, payment details, and app preferences here.", stepNumber: 6, totalSteps: 7),
            TutorialStep(identifier: .addTour, title: "Add New Tour", description: "Click here any time to start planning a new tour from scratch.", stepNumber: 7, totalSteps: 7)
        ]
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            content
                .onPreferenceChange(TutorialFramePreferenceKey.self) { frames in
                    self.viewFrames = frames
                }
            
            if isShowingTutorial {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture { finishTutorial(persist: false) } // Tapping away does not persist
                
                if !tutorialSteps.isEmpty && tutorialSteps.indices.contains(currentStepIndex),
                   let targetFrame = viewFrames[tutorialSteps[currentStepIndex].identifier] {
                    TutorialPopoverView(
                        step: tutorialSteps[currentStepIndex],
                        dontShowAgain: $dontShowAgain,
                        onBack: backStep,
                        onNext: nextStep,
                        onFinish: { finishTutorial(persist: dontShowAgain) }
                    )
                    .position(
                        x: targetFrame.maxX + 160,
                        y: targetFrame.midY
                    )
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
    }
    
    // MARK: - Logic
    
    private func backStep() {
        withAnimation { if currentStepIndex > 0 { currentStepIndex -= 1 } }
    }

    private func nextStep() {
        withAnimation {
            if currentStepIndex < tutorialSteps.count - 1 {
                currentStepIndex += 1
            }
        }
    }
    
    private func finishTutorial(persist: Bool) {
        withAnimation { isShowingTutorial = false }
        onFinish(persist)
    }
}
