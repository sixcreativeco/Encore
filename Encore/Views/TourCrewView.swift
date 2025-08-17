import SwiftUI
import FirebaseFirestore

struct TourCrewView: View {
    let tourID: String
    let ownerUserID: String

    @State private var crewMembers: [TourCrew] = []
    @State private var listener: ListenerRegistration?

    var body: some View {
        VStack(spacing: 8) {
            if crewMembers.isEmpty {
                Text("No crew members added.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(crewMembers) { member in
                    HStack {
                        Text(member.roles.joined(separator: ", ")).font(.subheadline)
                        Spacer()
                        Text(member.name).font(.subheadline).bold()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 70) // Set a minHeight
        .background(Color.black.opacity(0.15))
        .cornerRadius(12)
        .shadow(radius: 1)
        .onAppear { setupListener() }
        .onDisappear { listener?.remove() }
    }

    private func setupListener() {
        listener?.remove()
        
        let db = Firestore.firestore()
        
        listener = db.collection("tourCrew")
            .whereField("tourId", isEqualTo: tourID)
            .addSnapshotListener { snapshot, error in
            
            guard let documents = snapshot?.documents else {
                print("Error loading crew: \(error?.localizedDescription ?? "Unknown")")
                return
            }
                
            self.crewMembers = documents.compactMap { try? $0.data(as: TourCrew.self) }
        }
    }
}
