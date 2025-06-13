import Foundation

enum ContactFilter: String, CaseIterable {
    case all = "All"
    case Artist = "Artist"
    case SupportAct = "Support Act"
    case Crew = "Crew"
    case Guest = "Guest"

    var displayName: String {
        switch self {
        case .all: return "All"
        case .Artist: return "Artists"
        case .SupportAct: return "Support Acts"
        case .Crew: return "Crew"
        case .Guest: return "Guests"
        }
    }
}
