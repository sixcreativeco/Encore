import Foundation

class AppState: ObservableObject {
    @Published var userID: String? {
        didSet {
            if let userID = userID {
                UserDefaults.standard.set(userID, forKey: "userID")
            } else {
                UserDefaults.standard.removeObject(forKey: "userID")
            }
        }
    }

    @Published var selectedTab: String = "Dashboard"
    @Published var selectedTour: TourModel? = nil
    @Published var selectedShow: ShowModel? = nil
    @Published var tours: [TourModel] = []  // ✅ Added

    init() {
        self.userID = UserDefaults.standard.string(forKey: "userID")
    }

    func removeTour(tourID: String) {  // ✅ Added
        tours.removeAll { $0.id == tourID }
    }
}
