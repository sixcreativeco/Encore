import Foundation
import FirebaseFirestore

// Represents a guest staying in a hotel room.
struct HotelGuest: Codable, Identifiable, Hashable {
    var id: String { crewId } // Conform to Identifiable using crewId
    let crewId: String
    var name: String // Denormalized for easy display
}

// Represents a single room in a hotel booking.
struct HotelRoom: Codable, Identifiable, Hashable {
    var id = UUID().uuidString
    var roomNumber: String?
    var guests: [HotelGuest] = []
}

// Represents a complete hotel booking for a tour.
struct Hotel: Codable, Identifiable {
    @DocumentID var id: String?
    let tourId: String
    var name: String
    var address: String
    var city: String
    var country: String
    var timezone: String? // ADDED: To store the hotel's local timezone identifier.
    
    var checkInDate: Timestamp
    var checkOutDate: Timestamp
    var bookingReference: String?
    var rooms: [HotelRoom] = []
    
    @ServerTimestamp var createdAt: Timestamp?
}
