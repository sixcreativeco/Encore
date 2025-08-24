import Foundation

struct ExportConfiguration {
    // Content Toggles
    var includeItinerary: Bool = true
    var includeFlights: Bool = true
    var includeHotels: Bool = true
    var includeCrew: Bool = true
    var includeShowDetails: Bool = true
    var includeNotesSection: Bool = true
    var notes: String = ""

    // File Output & Cover Page Toggles
    var includeCoverPage: Bool = true
    enum CoverPageTheme: String, CaseIterable, Identifiable {
        case theme1 = "Theme 1"
        case theme2 = "Theme 2"
        case theme3 = "Theme 3" // New theme added
        var id: String { self.rawValue }
    }
    var coverPageTheme: CoverPageTheme = .theme1
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
    
    // Data Filtering
    var selectedShowID: String?
    var dateRangeStart: Date = Date()
    var dateRangeEnd: Date = Date()
}
