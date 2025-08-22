import Foundation

struct ExportConfiguration {
    // Content Toggles
    var includeItinerary: Bool = true
    var includeFlights: Bool = true
    var includeHotels: Bool = true
    var includeCrew: Bool = true
    var includeShowDetails: Bool = true
    var includeNotesSection: Bool = true
    var notes: String = "" // New property for user-inputted notes

    // File Output Toggles
    var includeCoverPage: Bool = true
    var separateFilesPerShow: Bool = false
    
    // Preset Management
    enum Preset: String, CaseIterable, Identifiable {
        case show = "Show"
        case guestList = "Guest List"
        case travel = "Travel"
        case date = "Date"
        case fullTour = "Full Tour"
        var id: String { self.rawValue }
    }
    var selectedPreset: Preset = .show
    var customPresetName: String = ""
    
    // Data Filtering
    var selectedShowID: String?
    var dateRangeStart: Date = Date()
    var dateRangeEnd: Date = Date()
}
