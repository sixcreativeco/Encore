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
            .padding(.leading, 8) // Lessened left padding
            .padding(.trailing, 16) // Increased right padding
            .padding(.top, 24)
            .padding(.bottom, 12)

            // The Divider has been removed.

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
                .padding(.leading, 8) // Lessened left padding
                .padding(.trailing, 16) // Increased right padding
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
        
        guard let notificationId = notification.id else { return }
        
        db.collection("tourCrew").document(notification.crewDocId)
            .updateData(["status": InviteStatus.accepted.rawValue]) { error in
                if let error = error {
                    print("Error accepting invite: \(error.localizedDescription)")
                    return
                }
                
                db.collection("notifications").document(notificationId).delete()
                
                appState.loadTours()
            }
    }
    
    private func declineInvite(_ notification: TourInvitationNotification) {
        let db = Firestore.firestore()
        
        guard let notificationId = notification.id else { return }
        
        db.collection("tourCrew").document(notification.crewDocId).delete()
        
        db.collection("notifications").document(notificationId).delete()
    }
}
