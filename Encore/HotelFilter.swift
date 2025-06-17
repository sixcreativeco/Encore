import Foundation

enum HotelFilter: String, CaseIterable {
    case all = "All"
    case Auckland
    case Wellington
    case Christchurch
    case Other

    var displayName: String {
        switch self {
        case .all: return "All"
        case .Auckland: return "Auckland"
        case .Wellington: return "Wellington"
        case .Christchurch: return "Christchurch"
        case .Other: return "Other"
        }
    }
}
