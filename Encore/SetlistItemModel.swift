import Foundation
import FirebaseFirestore

// The redundant 'String: Identifiable' extension has been removed.
// The native conformance from macOS 14 will be used instead.

struct SetlistItemModel: Identifiable, Hashable {
    var id: String
    var order: Int
    var itemType: ItemType

    enum ItemType: Hashable {
        case song(SongDetails)
        case marker(MarkerDetails)
    }
    
    init(id: String = UUID().uuidString, order: Int, itemType: ItemType) {
        self.id = id
        self.order = order
        self.itemType = itemType
    }
    
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let order = data["order"] as? Int,
              let typeString = data["type"] as? String
        else { return nil }

        self.id = document.documentID
        self.order = order

        if typeString == "song", let detailsData = data["details"] as? [String: Any] {
            self.itemType = .song(SongDetails(from: detailsData))
        } else if typeString == "marker", let detailsData = data["details"] as? [String: Any] {
            self.itemType = .marker(MarkerDetails(from: detailsData))
        } else {
            return nil
        }
    }

    func toFirestore() -> [String: Any] {
        var data: [String: Any] = ["id": id, "order": order]
        switch itemType {
        case .song(let details):
            data["type"] = "song"
            data["details"] = details.toFirestore()
        case .marker(let details):
            data["type"] = "marker"
            data["details"] = details.toFirestore()
        }
        return data
    }
}

struct SongDetails: Hashable {
    var name: String; var bpm: Int?; var key: String?; var tonality: String?
    var performanceNotes: String?; var lightingNotes: String?; var audioNotes: String?; var videoNotes: String?
    
    init(name: String, bpm: Int? = nil, key: String? = nil, tonality: String? = nil, performanceNotes: String? = nil, lightingNotes: String? = nil, audioNotes: String? = nil, videoNotes: String? = nil) {
        self.name = name; self.bpm = bpm; self.key = key; self.tonality = tonality
        self.performanceNotes = performanceNotes; self.lightingNotes = lightingNotes; self.audioNotes = audioNotes; self.videoNotes = videoNotes
    }
    
    init(from data: [String: Any]) {
        self.name = data["name"] as? String ?? ""; self.bpm = data["bpm"] as? Int
        self.key = data["key"] as? String; self.tonality = data["tonality"] as? String
        self.performanceNotes = data["performanceNotes"] as? String; self.lightingNotes = data["lightingNotes"] as? String
        self.audioNotes = data["audioNotes"] as? String; self.videoNotes = data["videoNotes"] as? String
    }
    
    func toFirestore() -> [String: Any] {
        return [
            "name": name, "bpm": bpm ?? NSNull(), "key": key ?? NSNull(), "tonality": tonality ?? NSNull(),
            "performanceNotes": performanceNotes ?? NSNull(), "lightingNotes": lightingNotes ?? NSNull(),
            "audioNotes": audioNotes ?? NSNull(), "videoNotes": videoNotes ?? NSNull()
        ]
    }
}

struct MarkerDetails: Hashable {
    var description: String; var duration: TimeInterval?
    
    init(description: String, duration: TimeInterval? = nil) { self.description = description; self.duration = duration }
    init(from data: [String: Any]) { self.description = data["description"] as? String ?? ""; self.duration = data["duration"] as? TimeInterval }
    func toFirestore() -> [String: Any] { return ["description": description, "duration": duration ?? NSNull()] }
}

struct PersonalNoteModel: Identifiable, Hashable {
    var id: String; var content: String; var authorCrewMemberID: String; var forCrewMemberID: String?; var createdAt: Date?
    
    init(id: String = UUID().uuidString, content: String, authorCrewMemberID: String, forCrewMemberID: String? = nil, createdAt: Date? = Date()) {
        self.id = id; self.content = content; self.authorCrewMemberID = authorCrewMemberID; self.forCrewMemberID = forCrewMemberID; self.createdAt = createdAt
    }

    init?(from document: DocumentSnapshot) {
        guard let data = document.data(), let content = data["content"] as? String, let authorCrewMemberID = data["authorCrewMemberID"] as? String else { return nil }
        self.id = document.documentID; self.content = content; self.authorCrewMemberID = authorCrewMemberID; self.forCrewMemberID = data["forCrewMemberID"] as? String
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
    }
    
    func toFirestore() -> [String: Any] {
        return ["content": content, "authorCrewMemberID": authorCrewMemberID, "forCrewMemberID": forCrewMemberID ?? NSNull(), "createdAt": createdAt != nil ? Timestamp(date: createdAt!) : FieldValue.serverTimestamp()]
    }
}
