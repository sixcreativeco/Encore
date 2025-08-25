import Foundation

// MARK: - Onboarding Data Models

/// The primary role selected by the user during onboarding.
enum UserRole: String, Codable, CaseIterable {
    case artist = "Artist"
    case manager = "Manager"
    case agency = "Agency"
}

/// Represents the typical size of a touring party for Artists and Managers.
enum TouringPartySize: String, Codable, CaseIterable {
    case oneToFive = "1-5"
    case sixToFifteen = "6-15"
    case sixteenPlus = "16+"

    var displayName: String {
        switch self {
        case .oneToFive: return "1-5 People"
        case .sixToFifteen: return "6-15 People"
        case .sixteenPlus: return "16+ People"
        }
    }
}

/// Represents the internal team size for an Agency.
enum AgencyTeamSize: String, Codable, CaseIterable {
    case oneToFive = "1-5"
    case sixToFifteen = "6-15"
    case sixteenPlus = "16+"

    var displayName: String {
        switch self {
        case .oneToFive: return "1-5 People"
        case .sixToFifteen: return "6-15 People"
        case .sixteenPlus: return "16+ People"
        }
    }
}

/// Represents the number of artists on an Agency's roster.
enum AgencyRosterSize: String, Codable, CaseIterable {
    case oneToTen = "1-10"
    case elevenToTwentyFive = "11-25"
    case twentySixPlus = "26+"

    var displayName: String {
        switch self {
        case .oneToTen: return "1-10 Artists"
        case .elevenToTwentyFive: return "11-25 Artists"
        case .twentySixPlus: return "26+ Artists"
        }
    }
}

/// Represents the primary goals a user wants to achieve with the app.
enum UserGoal: String, Codable, CaseIterable, Identifiable {
    case organizeShows = "Organize Shows & Schedules"
    case manageItinerary = "Build & Share Itineraries"
    case sellTickets = "Sell Tickets for Events"
    case manageCrew = "Manage Crew & Contacts"
    case exportDocuments = "Export Professional Documents"

    var id: String { self.rawValue }
}

/// A single structure to hold all data collected during the onboarding survey.
struct OnboardingData: Codable {
    let userId: String
    var role: UserRole?
    
    // Artist/Manager specific
    var touringPartySize: TouringPartySize?
    
    // Agency specific
    var agencyTeamSize: AgencyTeamSize?
    var agencyRosterSize: AgencyRosterSize?
    
    // Goals
    var goals: [UserGoal]?
    
    // Subscription
    var selectedPlan: String? // e.g., "Indie Artist", "Agency Pro"
    var billingCycle: String? // "monthly" or "annual"
}
