import Foundation

enum ContactFilter: String, CaseIterable {
    case all = "All"
    case artist = "Artist"
    case supportAct = "Support Act"
    case crew = "Crew"
    case guest = "Guest"

    var displayName: String {
        switch self {
        case .all: return "All"
        case .artist: return "Artists"
        case .supportAct: return "Support Acts"
        case .crew: return "Crew"
        case .guest: return "Guests"
        }
    }
}
