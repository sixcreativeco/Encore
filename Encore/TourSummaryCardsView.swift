import SwiftUI
import FirebaseFirestore

struct TourSummaryCardsView: View {
    var tourID: String
    @EnvironmentObject var appState: AppState

    @State private var tourManagerName: String = "-"
    @State private var tourManagerRole: String = "-"
    @State private var daysUntilTour: Int = 0
    @State private var totalShows: Int = 0

    var body: some View {
        HStack(spacing: 16) {
            summaryCard(title: tourManagerName, subtitle: tourManagerRole)
            summaryCard(title: "\(daysUntilTour)", subtitle: "Days Until Tour")
            summaryCard(title: "\(totalShows)", subtitle: "Total Shows")
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8) // optional small top gap after header
        .onAppear { loadTourSummaryData() }
    }

    private func summaryCard(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title3.bold())
            Text(subtitle).font(.subheadline).foregroundColor(.gray)
        }
        .padding(16) // internal padding inside each card
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 1)
    }

    private func loadTourSummaryData() {
        guard let userID = appState.userID else { return }
        let db = Firestore.firestore()

        db.collection("users").document(userID)
            .collection("tours").document(tourID)
            .collection("crew")
            .whereField("roles", arrayContains: "Tour Manager")
            .getDocuments { snapshot, _ in
                if let doc = snapshot?.documents.first {
                    self.tourManagerName = doc["name"] as? String ?? "-"
                    self.tourManagerRole = "Tour Manager"
                }
            }

        db.collection("users").document(userID)
            .collection("tours").document(tourID)
            .collection("shows")
            .getDocuments { snapshot, _ in
                self.totalShows = snapshot?.documents.count ?? 0
            }

        db.collection("users").document(userID)
            .collection("tours").document(tourID)
            .getDocument { doc, _ in
                if let data = doc?.data(), let startTimestamp = data["startDate"] as? Timestamp {
                    let startDate = startTimestamp.dateValue()
                    let days = Calendar.current.dateComponents([.day], from: Date(), to: startDate).day ?? 0
                    self.daysUntilTour = max(days, 0)
                }
            }
    }
}
