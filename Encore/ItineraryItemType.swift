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
    case headline
    case travel
    case content
    case merch
    
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
        case .headline: return "Headliner Set"
        case .travel: return "Travel"
        case .content: return "Content"
        case .merch: return "Merchandise"
        }
    }
    
    var iconName: String {
        switch self {
        case .loadIn: return "truck.box"
        case .soundcheck: return "music.mic"
        case .doors: return "door.left.hand.open"
        case .packOut: return "shippingbox"
        case .flight: return "airplane"
        case .arrival: return "airplane.arrival"
        case .hotel: return "bed.double.fill"
        case .meeting: return "person.2.fill"
        case .freeTime: return "clock.fill"
        case .catering: return "fork.knife"
        case .custom: return "calendar"
        case .headline: return "music.mic.circle.fill"
        case .travel: return "car.fill"
        case .content: return "camera.fill"
        case .merch: return "tshirt.fill"
        }
    }

    // FIX: This logic now lives inside the enum where it belongs.
    var isShowTiming: Bool {
        switch self {
        case .loadIn, .soundcheck, .doors, .headline, .packOut:
            return true
        default:
            return false
        }
    }

    // FIX: This now correctly maps the enum case to the Firestore field name.
    var firestoreShowKey: String? {
        switch self {
        case .loadIn: return "loadIn"
        case .soundcheck: return "soundCheck"
        case .doors: return "doorsOpen"
        case .headline: return "headlinerSetTime"
        case .packOut: return "packOut"
        default: return nil
        }
    }
}
