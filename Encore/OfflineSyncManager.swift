import Foundation
import Firebase
import FirebaseStorage
import Network

class OfflineSyncManager: ObservableObject {
    static let shared = OfflineSyncManager()

    @Published var tours: [TourModel] = []
    @Published var showCache: [String: [ShowModel]] = [:]
    @Published var isOnline: Bool = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private init() {
        startNetworkMonitoring()
    }

    func upsertTour(_ tour: TourModel) {
        let db = Firestore.firestore()
        let ref = db.collection("tours").document(tour.id)

        var tourData: [String: Any] = [
            "tourName": tour.name,
            "artist": tour.artist,
            "startDate": tour.startDate,
            "endDate": tour.endDate,
            "createdAt": tour.createdAt
        ]

        if let posterURL = tour.posterURL {
            tourData["posterURL"] = posterURL
        }

        ref.setData(tourData)
    }

    func upsertShow(_ show: ShowModel, for tourID: String) {
        let db = Firestore.firestore()
        let ref = db.collection("tours").document(tourID).collection("shows").document(show.id)

        var showData: [String: Any] = [
            "city": show.city,
            "venue": show.venue,
            "address": show.address,
            "date": Timestamp(date: show.date)
        ]

        if let country = show.country {
            showData["country"] = country
        }

        ref.setData(showData)
    }

    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isOnline = (path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }
}
