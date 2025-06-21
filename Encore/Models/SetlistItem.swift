import Foundation
import FirebaseFirestore

// FIX: Added Equatable conformance for SwiftUI animations.
struct SetlistItem: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    let showId: String
    let tourId: String
    var order: Int
    var type: ItemType

    // Song-specific details
    var songTitle: String?
    var bpm: Int?
    var key: String?
    var tonality: String?
    var performanceNotes: String?
    var lightingNotes: String?
    var audioNotes: String?
    var videoNotes: String?
    
    // Marker-specific details
    var markerDescription: String?
    var markerDuration: TimeInterval?

    enum ItemType: String, Codable {
        case song, marker
    }
}
