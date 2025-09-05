import Foundation
import FirebaseFirestore

struct TicketAvailability: Codable, Hashable {
    var type: AvailabilityType
    var startDate: Timestamp?
    var endDate: Timestamp?
    var dependsOnReleaseID: String?
    var endWhenSoldOut: Bool? // --- THIS IS THE ADDITION ---
    
    enum AvailabilityType: String, Codable, CaseIterable, CustomStringConvertible {
        case onSaleImmediately = "On Sale Immediately"
        case scheduled = "Scheduled Sale"
        case afterPreviousSellsOut = "After Previous Sells Out"
        
        var description: String {
            return self.rawValue
        }
        
        var helperText: String {
            switch self {
            case .onSaleImmediately:
                return "Tickets will be available as soon as this event is published."
            case .scheduled:
                return "Tickets will only be available between the specified dates."
            case .afterPreviousSellsOut:
                return "Sale will begin automatically when another ticket release sells out."
            }
        }
        
        var shouldShowDatePickers: Bool {
            return self == .scheduled
        }
    }
}
