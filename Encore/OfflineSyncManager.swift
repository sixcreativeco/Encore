import Foundation
import Firebase
import FirebaseStorage
import Network

class OfflineSyncManager: ObservableObject {
    static let shared = OfflineSyncManager()

    // MARK: - Published Properties
    @Published var tours: [TourModel] = []
    @Published var showCache: [String: [ShowModel]] = [:]
    @Published var isOnline: Bool = false  // ✅ Now publicly observable

    // MARK: - Sync Queues
    private var syncQueue: [TourModel] = []

    // MARK: - File Names
    private let tourFileName = "tours_cache.json"

    // MARK: - Network
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private init() {
        loadToursFromDisk()
        startNetworkMonitoring()
    }

    // MARK: - Tour Methods

    func upsertTour(_ tour: TourModel) {
        if let index = tours.firstIndex(where: { $0.id == tour.id }) {
            tours[index] = tour
        } else {
            tours.append(tour)
        }

        saveToursToDisk()
        queueForSync(tour)
    }

    private func queueForSync(_ tour: TourModel) {
        syncQueue.append(tour)
        trySync()
    }

    private func trySync() {
        guard !syncQueue.isEmpty else { return }

        let queueCopy = syncQueue
        syncQueue.removeAll()

        for tour in queueCopy {
            saveToFirebase(tour) { success in
                if !success {
                    self.syncQueue.append(tour)
                }
            }
        }
    }

    private func saveToFirebase(_ tour: TourModel, completion: @escaping (Bool) -> Void) {
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

        ref.setData(tourData) { error in
            if let error = error {
                print("❌ Error uploading tour: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    private func saveToursToDisk() {
        do {
            let data = try JSONEncoder().encode(tours)
            try data.write(to: getFileURL(named: tourFileName))
        } catch {
            print("❌ Failed to save tours to disk:", error.localizedDescription)
        }
    }

    private func loadToursFromDisk() {
        let url = getFileURL(named: tourFileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            let data = try Data(contentsOf: url)
            tours = try JSONDecoder().decode([TourModel].self, from: data)
        } catch {
            print("❌ Failed to load tours from disk:", error.localizedDescription)
        }
    }

    // MARK: - Show Methods

    func upsertShow(_ show: ShowModel, for tourID: String) {
        var existing = showCache[tourID] ?? []
        if let index = existing.firstIndex(where: { $0.id == show.id }) {
            existing[index] = show
        } else {
            existing.append(show)
        }
        showCache[tourID] = existing
        saveShowsToDisk(for: tourID)
        queueShowForSync(show, tourID: tourID)
    }

    func cacheShows(for tourID: String, shows: [ShowModel]) {
        showCache[tourID] = shows
        saveShowsToDisk(for: tourID)
    }

    func getShows(for tourID: String) -> [ShowModel] {
        return showCache[tourID] ?? []
    }

    private func saveShowsToDisk(for tourID: String) {
        do {
            let data = try JSONEncoder().encode(showCache[tourID])
            try data.write(to: getFileURL(named: "shows_\(tourID).json"))
        } catch {
            print("❌ Failed to save shows to disk for \(tourID):", error.localizedDescription)
        }
    }

    private func loadShowsFromDisk(for tourID: String) {
        let url = getFileURL(named: "shows_\(tourID).json")
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            let data = try Data(contentsOf: url)
            let shows = try JSONDecoder().decode([ShowModel].self, from: data)
            showCache[tourID] = shows
        } catch {
            print("❌ Failed to load shows from disk for \(tourID):", error.localizedDescription)
        }
    }

    private func queueShowForSync(_ show: ShowModel, tourID: String) {
        // Placeholder for future sync logic
    }

    // MARK: - File Helpers

    private func getFileURL(named fileName: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(fileName)
    }

    // MARK: - Network Monitoring

    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isOnline = (path.status == .satisfied)
            }

            if path.status == .satisfied {
                self.trySync()
            }
        }
        monitor.start(queue: queue)
    }
}
