import SwiftUI
import FirebaseFirestore

struct NotificationsView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Notifications")
                    .font(.title2.bold())
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 8)
            .padding(.trailing, 16)
            .padding(.top, 24)
            .padding(.bottom, 12)

            // Content
            if appState.notifications.isEmpty {
                Text("You have no new notifications.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(appState.notifications) { notification in
                            notificationCard(notification)
                        }
                    }
                    .padding(.top, 12)
                }
                .padding(.leading, 8)
                .padding(.trailing, 16)
            }
        }
    }
    
    private func notificationCard(_ notification: TourInvitationNotification) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(notification.inviterName) invited you to the tour:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("\(notification.artistName) - \(notification.tourName)")
                .fontWeight(.bold)
                
            Text("Role: \(notification.roles.joined(separator: ", "))")
                .font(.subheadline)
            
            HStack(spacing: 12) {
                Button("Accept") {
                    acceptInvite(notification)
                }
                .buttonStyle(PrimaryButtonStyle(color: .green))
                
                Button("Decline") {
                    declineInvite(notification)
                }
                .buttonStyle(PrimaryButtonStyle(color: .red))
            }
            .padding(.top, 8)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.25))
        .cornerRadius(12)
    }
    
    private func acceptInvite(_ notification: TourInvitationNotification) {
        let db = Firestore.firestore()
        
        guard let notificationId = notification.id, let userId = appState.userID else { return }
        
        // --- FIX START ---
        // Use a batch to perform all updates atomically
        let batch = db.batch()
        
        // 1. Update the tourCrew document to set the status to "accepted"
        let crewRef = db.collection("tourCrew").document(notification.crewDocId)
        batch.updateData(["status": InviteStatus.accepted.rawValue], forDocument: crewRef)
        
        // 2. Update the main tour document to add this user to the members map for secure access
        let tourRef = db.collection("tours").document(notification.tourId)
        batch.setData(["members": [userId: "crew"]], forDocument: tourRef, merge: true)

        // 3. Delete the notification document now that it has been actioned
        let notificationRef = db.collection("notifications").document(notificationId)
        batch.deleteDocument(notificationRef)
        
        // 4. Commit all three operations at once
        batch.commit { error in
            if let error = error {
                print("Error accepting invite: \(error.localizedDescription)")
                return
            }
            // Reload user's tours to reflect the new membership immediately
            appState.loadTours()
        }
        // --- FIX END ---
    }
    
    private func declineInvite(_ notification: TourInvitationNotification) {
        let db = Firestore.firestore()
        
        guard let notificationId = notification.id else { return }
        
        // Use a batch to delete both documents atomically
        let batch = db.batch()
        
        let crewRef = db.collection("tourCrew").document(notification.crewDocId)
        batch.deleteDocument(crewRef)
        
        let notificationRef = db.collection("notifications").document(notificationId)
        batch.deleteDocument(notificationRef)
        
        batch.commit()
    }
}
