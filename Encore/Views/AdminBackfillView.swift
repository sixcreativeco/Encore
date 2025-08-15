import SwiftUI
import FirebaseFirestore

// This is a temporary view to perform a one-time data migration.
struct AdminBackfillView: View {
    @State private var statusMessage: String = "Ready to start."
    @State private var isLoading: Bool = false
    @State private var isComplete: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Admin Data Tool")
                .font(.title2.bold())
            
            Text("Press the button below to automatically update all your existing Tour documents with the new 'members' map. This is required for the new security rules to work correctly for your existing data.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                Task {
                    await performBackfill()
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .colorInvert()
                    } else {
                        Image(systemName: "wand.and.stars")
                        Text("Run Backfill Script")
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
    
    private func performBackfill() async {
        await MainActor.run {
            self.isLoading = true
            self.statusMessage = "Processing... Please wait."
        }

        let db = Firestore.firestore()
        
        do {
            // 1. Fetch all documents from the tourCrew collection.
            let crewSnapshot = try await db.collection("tourCrew").getDocuments()
            statusMessage = "Fetched \(crewSnapshot.count) crew entries..."

            // 2. Group all user IDs by their tour ID.
            var tourToUserMap = [String: Set<String>]()
            for document in crewSnapshot.documents {
                let crewData = document.data()
                if let tourId = crewData["tourId"] as? String,
                   let userId = crewData["userId"] as? String,
                   let status = crewData["status"] as? String,
                   status == "accepted" {
                    tourToUserMap[tourId, default: Set()].insert(userId)
                }
            }
            statusMessage = "Grouped crew for \(tourToUserMap.count) unique tours..."

            // 3. Prepare a batch write to update all tours.
            let batch = db.batch()
            var updatedTourCount = 0

            for (tourId, userIds) in tourToUserMap {
                let tourRef = db.collection("tours").document(tourId)
                let tourDoc = try await tourRef.getDocument()

                if let tourData = tourDoc.data(), let ownerId = tourData["ownerId"] as? String {
                    var membersMap: [String: String] = [:]
                    
                    // Add the owner to the map
                    membersMap[ownerId] = "owner"
                    
                    // Add all accepted crew members
                    for uid in userIds {
                        if membersMap[uid] == nil { // Don't overwrite owner role
                            membersMap[uid] = "crew"
                        }
                    }
                    
                    // Add the update operation to the batch.
                    batch.updateData(["members": membersMap], forDocument: tourRef)
                    updatedTourCount += 1
                }
            }
            
            // 4. Commit the batch to perform all updates at once.
            if updatedTourCount > 0 {
                try await batch.commit()
            }
            
            await MainActor.run {
                self.isLoading = false
                self.isComplete = true
                self.statusMessage = "Success! 🎉 Updated \(updatedTourCount) tour documents. You can now remove this admin tool."
            }

        } catch {
            await MainActor.run {
                self.isLoading = false
                self.statusMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
}
