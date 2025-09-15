import Foundation
import FirebaseFirestore

enum LandingPageTheme: String, Codable, CaseIterable, Identifiable {
    case `default` = "Default"
    case darkMode = "Dark Mode"
    case print = "Print"
    case scrapbook = "Scrapbook"
    
    var id: String { self.rawValue }
}

struct Tour: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    let ownerId: String
    var tourName: String
    var artist: String
    var startDate: Timestamp
    var endDate: Timestamp
    var posterURL: String?
    
    // --- UPDATED SECTION: Landing Page Properties ---
    var landingPageUrl: String?
    var landingPageHeaderImageUrl: String?
    var landingPageHeaderVideoUrl: String? // ADDED for video support
    var landingPageScrapbookImageUrl2: String? // ADDED for scrapbook theme
    var landingPageHeaderFocusY: Double? // ADDED for image repositioning (0.0=top, 1.0=bottom)
    var landingPageBio: String?
    var landingPageTheme: LandingPageTheme?
    var isLandingPagePublished: Bool? // ADDED for publish state
    // --- END OF SECTION ---
    
    var stagePlotImageURL: String?
    var defaultEventDescription: String?
    var defaultImportantInfo: String?
    var defaultTicketTypes: [TicketType]?
    
    @ServerTimestamp var createdAt: Timestamp?

    static func == (lhs: Tour, rhs: Tour) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
