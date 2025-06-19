import Foundation
import FirebaseFirestore
import SwiftUI

// Enum to define the different types of items that can be in a setlist.
enum SetlistItemType: String, Codable, CaseIterable, Identifiable {
    case song = "Song"
    case note = "Note"
    case lighting = "Lighting Cue"
    case tech = "Technical Change"

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .song: return "music.mic"
        case .note: return "pencil"
        case .lighting: return "lightbulb.fill"
        case .tech: return "wrench.and.screwdriver.fill"
        }
    }
}

// The data model for a single item in the setlist.
struct SetlistItemModel: Identifiable, Codable, Hashable {
    var id: String
    var order: Int
    var type: SetlistItemType
    
    // Fields for all types
    var title: String? // Used for Song name
    var notes: String? // Used for Note, Lighting notes, Tech notes
    
    // Fields for Lighting Cues
    var mainColorHex: String? // Stored as a hex string, e.g., "#FF0000"

    // Default initializer
    init(id: String = UUID().uuidString, order: Int, type: SetlistItemType, title: String? = nil, notes: String? = nil, mainColorHex: String? = nil) {
        self.id = id
        self.order = order
        self.type = type
        self.title = title
        self.notes = notes
        self.mainColorHex = mainColorHex
    }

    // Initializer for decoding from a Firestore document.
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let order = data["order"] as? Int,
              let typeString = data["type"] as? String,
              let type = SetlistItemType(rawValue: typeString) else {
            return nil
        }

        self.id = document.documentID
        self.order = order
        self.type = type
        self.title = data["title"] as? String
        self.notes = data["notes"] as? String
        self.mainColorHex = data["mainColorHex"] as? String
    }

    // Helper to convert the model to a dictionary for Firestore.
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "order": order,
            "type": type.rawValue
        ]
        
        if let title = title { data["title"] = title }
        if let notes = notes { data["notes"] = notes }
        if let mainColorHex = mainColorHex { data["mainColorHex"] = mainColorHex }

        return data
    }
    
    // Computed property to easily access the color for Lighting Cues
    var mainColor: Color {
        guard let hex = mainColorHex else { return .clear }
        // This is a simplified hex-to-color converter. A production app might use a more robust one.
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        
        if scanner.scanHexInt64(&hexNumber) {
            let r = Double((hexNumber & 0xff0000) >> 16) / 255
            let g = Double((hexNumber & 0x00ff00) >> 8) / 255
            let b = Double(hexNumber & 0x0000ff) / 255
            return Color(red: r, green: g, blue: b)
        }
        
        return .clear
    }
}
