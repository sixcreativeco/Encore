import Foundation

/// Defines unique identifiers for UI elements that the tutorial can attach to.
enum TutorialStepIdentifier: String, CaseIterable {
    case dashboard
    case tours
    case tickets
    case database
    case export
    case myAccount
    case addTour
}

/// Represents a single step in the guided tutorial.
struct TutorialStep: Identifiable {
    let id = UUID()
    let identifier: TutorialStepIdentifier
    let title: String
    let description: String
    let stepNumber: Int
    let totalSteps: Int
}
