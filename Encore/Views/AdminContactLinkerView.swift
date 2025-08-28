import SwiftUI
import FirebaseFirestore

struct AdminContactLinkerView: View {
    @EnvironmentObject var appState: AppState
    @State private var statusMessage: String = "Ready to link legacy crew to contacts."
    @State private var isLoading: Bool = false
    @State private var isComplete: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Admin Data Tool: Link Crew to Contacts")
                .font(.title3.bold())
            
            Text("Press the button to find all crew members that do not have a master contact record and create one for them. This is a one-time operation to update your old data.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                Task { await performLinking() }
            }) {
                HStack {
                    if isLoading {
                        ProgressView().colorInvert()
                    } else {
                        Image(systemName: "link")
                        Text("Link Crew & Contacts")
                    }
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isComplete ? Color.green : Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(isLoading || isComplete)
            
            Text(statusMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(16)
    }
    
    private func performLinking() async {
        guard let ownerId = appState.userID else {
            statusMessage = "Error: Not logged in."
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.statusMessage = "Processing... Please wait."
        }

        let db = Firestore.firestore()
        
        do {
            // 1. Fetch all crew documents without a contactId
            let crewSnapshot = try await db.collection("tourCrew")
                .whereField("ownerId", isEqualTo: ownerId)
                .whereField("contactId", isEqualTo: NSNull())
                .getDocuments()

            let crewToProcess = crewSnapshot.documents.compactMap { try? $0.data(as: TourCrew.self) }
            
            if crewToProcess.isEmpty {
                await MainActor.run {
                    self.isLoading = false
                    self.isComplete = true
                    self.statusMessage = "Success! No unlinked crew members found."
                }
                return
            }
            
            statusMessage = "Found \(crewToProcess.count) unlinked crew members. Processing..."
            let batch = db.batch()
            var linkedCount = 0

            for var crew in crewToProcess {
                // 2. Create a new Contact document for this crew member
                let newContact = Contact(
                    ownerId: ownerId,
                    name: crew.name,
                    roles: crew.roles,
                    email: crew.email,
                    phone: crew.phone
                )
                let contactRef = db.collection("contacts").document()
                try batch.setData(from: newContact, forDocument: contactRef)
                
                // 3. Update the crew document with the new contactId
                if let crewId = crew.id {
                    let crewRef = db.collection("tourCrew").document(crewId)
                    batch.updateData(["contactId": contactRef.documentID], forDocument: crewRef)
                    linkedCount += 1
                }
            }
            
            // 4. Commit the batch
            try await batch.commit()
            
            await MainActor.run {
                self.isLoading = false
                self.isComplete = true
                self.statusMessage = "Success! 🎉 Linked \(linkedCount) crew members to new contact records."
            }

        } catch {
            await MainActor.run {
                self.isLoading = false
                self.statusMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
}
