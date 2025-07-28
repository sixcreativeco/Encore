import Foundation
import FirebaseFirestore

class FirebaseHotelService {
    static let shared = FirebaseHotelService()
    private let db = Firestore.firestore()
    
    private init() {}

    // MARK: - Hotel Functions

    /// Adds a real-time listener for hotels associated with a specific tour.
    func addHotelsListener(forTour tourID: String, completion: @escaping ([Hotel]) -> Void) -> ListenerRegistration {
        return db.collection("hotels")
            .whereField("tourId", isEqualTo: tourID)
            .order(by: "checkInDate")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching hotel snapshots: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                let hotels = documents.compactMap { try? $0.data(as: Hotel.self) }
                completion(hotels)
            }
    }

    /// Saves a new hotel document and creates associated itinerary items in a single transaction.
    func saveHotel(_ hotel: Hotel, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()
        
        // 1. Create a new document reference for the hotel
        let hotelRef = db.collection("hotels").document()
        
        // 2. Set the data for the new hotel
        do {
            try batch.setData(from: hotel, forDocument: hotelRef)
        } catch {
            completion(error)
            return
        }
        
        // 3. Create Itinerary Item for Check-in
        let checkInItem = ItineraryItem(
            tourId: hotel.tourId,
            showId: nil, // Hotels are not tied to specific shows
            title: "Check-in: \(hotel.name)",
            type: ItineraryItemType.hotel.rawValue,
            timeUTC: hotel.checkInDate,
            subtitle: hotel.address,
            notes: hotel.bookingReference,
            timezone: hotel.timezone, // MODIFIED: Pass the hotel's timezone
            visibility: "Everyone",
            visibleTo: nil
        )
        let checkInRef = db.collection("itineraryItems").document()
        try? batch.setData(from: checkInItem, forDocument: checkInRef)
        
        // 4. Create Itinerary Item for Check-out
        let checkOutItem = ItineraryItem(
            tourId: hotel.tourId,
            showId: nil,
            title: "Check-out: \(hotel.name)",
            type: ItineraryItemType.hotel.rawValue,
            timeUTC: hotel.checkOutDate,
            subtitle: hotel.address,
            notes: nil,
            timezone: hotel.timezone, // MODIFIED: Pass the hotel's timezone
            visibility: "Everyone",
            visibleTo: nil
        )
        let checkOutRef = db.collection("itineraryItems").document()
        try? batch.setData(from: checkOutItem, forDocument: checkOutRef)
        
        // 5. Commit the batch
        batch.commit(completion: completion)
    }
    
    /// Updates an existing hotel document in Firestore.
    func updateHotel(_ hotel: Hotel, completion: @escaping (Error?) -> Void) {
        guard let hotelID = hotel.id else {
            completion(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Hotel ID is missing."]))
            return
        }
        
        do {
            try db.collection("hotels").document(hotelID).setData(from: hotel, merge: true, completion: completion)
        } catch {
            completion(error)
        }
    }

    /// Deletes a hotel document from Firestore.
    func deleteHotel(hotelID: String, completion: @escaping (Error?) -> Void) {
        db.collection("hotels").document(hotelID).delete(completion: completion)
    }
}
