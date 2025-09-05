import Foundation
import FirebaseFirestore

struct HotelGuest: Codable, Identifiable, Hashable {
    var id: String { crewId }
    let crewId: String
    var name: String
}

struct HotelRoom: Codable, Identifiable, Hashable {
    var id = UUID().uuidString
    var roomNumber: String?
    var guests: [HotelGuest] = []
}

struct Hotel: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    let tourId: String
    var ownerId: String
    var name: String
    var address: String
    var city: String
    var country: String
    var timezone: String // --- THIS WAS THE FIX --- (Changed from String?)
    
    var checkInDate: Timestamp
    var checkOutDate: Timestamp
    var bookingReference: String?
    var rooms: [HotelRoom] = []
    
    @ServerTimestamp var createdAt: Timestamp?

    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Conformance to Equatable
    static func == (lhs: Hotel, rhs: Hotel) -> Bool {
        lhs.id == rhs.id
    }
}
