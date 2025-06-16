import SwiftUI
import FirebaseFirestore

struct TourCrewView: View {
    var tourID: String

    @State private var crewMembers: [CrewMember] = []
    @State private var showAddCrew = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Crew", onAdd: {
                showAddCrew = true
            })
            .sheet(isPresented: $showAddCrew) {
                AddCrewPopupView(tourID: tourID)
            }

            VStack(spacing: 8) {
                ForEach(crewMembers, id: \.id) { member in
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
        .onAppear {
            setupListener()
        }
    }

    private func setupListener() {
        guard let userID = AuthManager.shared.user?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userID)
            .collection("tours").document(tourID)
            .collection("crew")
            .order(by: "name")
            .addSnapshotListener { snapshot, _ in
                self.crewMembers = snapshot?.documents.compactMap { doc in
                    CrewMember(
                        id: doc.documentID,
                        name: doc["name"] as? String ?? "-",
                        email: doc["email"] as? String ?? "-",
                        roles: doc["roles"] as? [String] ?? []
                    )
                } ?? []
            }
    }
}
