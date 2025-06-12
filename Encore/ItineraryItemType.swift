import Foundation

enum ItineraryItemType: String, Codable, CaseIterable {
    case loadIn
    case soundcheck
    case doors
    case packOut
    case flight
    case arrival
    case hotel
    case meeting
    case freeTime
    case catering
    case custom
    
    var displayName: String {
        switch self {
        case .loadIn: return "Load In"
        case .soundcheck: return "Soundcheck"
        case .doors: return "Doors Open"
        case .packOut: return "Pack Out"
        case .flight: return "Flight"
        case .arrival: return "Arrival"
        case .hotel: return "Hotel"
        case .meeting: return "Meeting"
        case .freeTime: return "Free Time"
        case .catering: return "Catering"
        case .custom: return "Custom"
        }
    }
    
    var iconName: String {
        switch self {
        case .loadIn: return "truck"
        case .soundcheck: return "music.mic"
        case .doors: return "door.left.hand.open"
        case .packOut: return "shippingbox"
        case .flight: return "airplane"
        case .arrival: return "airplane.arrival"
        case .hotel: return "bed.double"
        case .meeting: return "person.2"
        case .freeTime: return "clock"
        case .catering: return "fork.knife"
        case .custom: return "calendar"
        }
    }
}
