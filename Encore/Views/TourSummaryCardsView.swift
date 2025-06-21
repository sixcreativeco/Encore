import SwiftUI
import FirebaseFirestore

struct TourSummaryCardsView: View {
    var tourID: String
    var ownerUserID: String // Kept for compatibility, but new queries are simpler

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
        .padding(.top, 8)
        .onAppear { loadTourSummaryData() }
    }

    private func summaryCard(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title3.bold())
            Text(subtitle).font(.subheadline).foregroundColor(.gray)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 1)
    }

    // --- FIX IS HERE ---
    private func loadTourSummaryData() {
        let db = Firestore.firestore()
        
        // 1. Fetch Tour Manager from the new top-level /tourCrew collection
        db.collection("tourCrew")
            .whereField("tourId", isEqualTo: tourID)
            .whereField("roles", arrayContains: "Tour Manager")
            .limit(to: 1) // We only need the first one
            .getDocuments { snapshot, _ in
                if let doc = snapshot?.documents.first, let crewMember = try? doc.data(as: TourCrew.self) {
                    self.tourManagerName = crewMember.name
                    self.tourManagerRole = "Tour Manager"
                } else {
                    self.tourManagerName = "Not Assigned"
                    self.tourManagerRole = "Tour Manager"
                }
            }

        // 2. Fetch total shows from the new top-level /shows collection
        db.collection("shows")
            .whereField("tourId", isEqualTo: tourID)
            .getDocuments { snapshot, _ in
                self.totalShows = snapshot?.documents.count ?? 0
            }

        // 3. Fetch the tour start date from the new top-level /tours collection
        db.collection("tours").document(tourID).getDocument { doc, _ in
            if let tour = try? doc?.data(as: Tour.self) {
                let days = Calendar.current.dateComponents([.day], from: Date(), to: tour.startDate.dateValue()).day ?? 0
                self.daysUntilTour = max(days, 0)
            }
        }
    }
}
