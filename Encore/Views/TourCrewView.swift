import SwiftUI
import FirebaseFirestore

struct TourCrewView: View {
    var tourID: String
    var ownerUserID: String

    // FIX: The state now uses our new top-level TourCrew model.
    @State private var crewMembers: [TourCrew] = []
    @State private var showAddCrew = false
    @State private var listener: ListenerRegistration?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Crew", onAdd: {
                showAddCrew = true
            })
            .sheet(isPresented: $showAddCrew) {
                // This call is now correct, as AddCrewPopupView has been refactored.
                AddCrewPopupView(tourID: tourID)
            }

            VStack(spacing: 8) {
                // FIX: The ForEach now iterates correctly over the new [TourCrew] array.
                // The 'id' is implicitly handled by the Identifiable conformance.
                ForEach(crewMembers) { member in
                    HStack {
                        Text(member.roles.joined(separator: ", ")).font(.subheadline)
                        Spacer()
                        Text(member.name).font(.subheadline).bold()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 1)
        }
        .frame(maxWidth: .infinity)
        .onAppear { setupListener() }
        .onDisappear { listener?.remove() } // Add cleanup for the listener
    }

    private func setupListener() {
        listener?.remove() // Prevent duplicate listeners
        
        let db = Firestore.firestore()
        
        // FIX: This now listens for real-time updates on the top-level /tourCrew collection
        // and filters for the current tourID.
        listener = db.collection("tourCrew")
            .whereField("tourId", isEqualTo: tourID)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error loading crew: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                // We use Codable to automatically decode into our new TourCrew model.
                self.crewMembers = documents.compactMap { try? $0.data(as: TourCrew.self) }
            }
    }
}
