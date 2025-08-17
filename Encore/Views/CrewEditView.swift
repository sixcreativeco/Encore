import SwiftUI
import FirebaseFirestore

struct CrewEditView: View {
    @Environment(\.dismiss) var dismiss
    let tour: Tour
    
    // This view will have its own dedicated listener for crew members
    @State private var crewMembers: [TourCrew] = []
    @State private var listener: ListenerRegistration?
    
    // State for confirmation alerts
    @State private var crewMemberToDelete: TourCrew?
    @State private var isShowingDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Manage Crew")
                    .font(.largeTitle.bold())
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()

            // Main Content
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // --- THIS IS THE FIX: Part 1 ---
                    // We tell AddCrewSectionView NOT to show its internal list.
                    AddCrewSectionView(tour: tour, showCrewList: false)

                    // This section is now the single source for displaying the crew list.
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Crew")
                            .font(.headline)
                        
                        if crewMembers.isEmpty {
                            Text("No crew members have been added yet.")
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(crewMembers) { crew in
                                // The card now includes the delete button and other actions.
                                existingCrewMemberCard(crew)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 700)
        .onAppear(perform: setupListener)
        .onDisappear { listener?.remove() }
        .alert("Remove Crew Member?", isPresented: $isShowingDeleteAlert, presenting: crewMemberToDelete) { crewToDelete in
            Button("Remove \(crewToDelete.name)", role: .destructive) {
                Task {
                    await removeCrewMember(crewToDelete)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { crewToDelete in
            Text("Are you sure you want to remove \(crewToDelete.name) from this tour? They will lose all access to the tour's data.")
        }
    }

    // A card for displaying and managing an existing crew member
    @ViewBuilder
    private func existingCrewMemberCard(_ crew: TourCrew) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(crew.name).fontWeight(.bold)
                Text(crew.roles.joined(separator: ", ")).font(.subheadline).foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Display and refresh the invite code if the user hasn't accepted yet
            if crew.status == .invited, let code = crew.invitationCode {
                HStack {
                    Text(code)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.orange)
                    
                    Button(action: {
                        Task { await refreshInviteCode(for: crew) }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                    .help("Refresh Invite Code")
                }
            }
            
            // --- THIS IS THE FIX: Part 2 ---
            // The delete button is now part of this single, unified crew card.
            Button(role: .destructive, action: {
                crewMemberToDelete = crew
                isShowingDeleteAlert = true
            }) {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }
    
    // Sets up a real-time listener for the crew list
    private func setupListener() {
        guard let tourID = tour.id else { return }
        listener?.remove()
        
        let db = Firestore.firestore()
        listener = db.collection("tourCrew")
            .whereField("tourId", isEqualTo: tourID)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error loading crew for edit view: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                self.crewMembers = documents.compactMap { try? $0.data(as: TourCrew.self) }
            }
    }
    
    // Deletes the crew member from the tour
    private func removeCrewMember(_ crew: TourCrew) async {
        guard let crewId = crew.id, let tourId = tour.id else { return }
        
        let db = Firestore.firestore()
        let batch = db.batch()

        // 1. Delete the tourCrew document
        let crewRef = db.collection("tourCrew").document(crewId)
        batch.deleteDocument(crewRef)

        // 2. Remove the user from the tour's 'members' map for security
        if let userId = crew.userId {
            let tourRef = db.collection("tours").document(tourId)
            batch.updateData(["members.\(userId)": FieldValue.delete()], forDocument: tourRef)
        }
        
        do {
            try await batch.commit()
            print("✅ Successfully removed crew member.")
        } catch {
            print("❌ Error removing crew member: \(error.localizedDescription)")
        }
    }
    
    // Generates a new invitation code for a crew member
    private func refreshInviteCode(for crew: TourCrew) async {
        guard let crewId = crew.id, let tourId = tour.id else { return }
        let inviterId = tour.ownerId

        do {
            // Call the secure backend API to generate a new code
            let newCode = try await InvitationAPI.createInvitation(
                crewDocId: crewId,
                tourId: tourId,
                inviterId: inviterId
            )
            
            if let newCode = newCode {
                // Update the crew document with the new code
                let crewRef = Firestore.firestore().collection("tourCrew").document(crewId)
                try await crewRef.updateData(["invitationCode": newCode])
                print("✅ Successfully refreshed invite code.")
            }
        } catch {
            print("❌ Error refreshing invite code: \(error.localizedDescription)")
        }
    }
}
