import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

struct MyAccountView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var syncManager = OfflineSyncManager.shared

    // User Profile State
    @State private var userName: String = "Loading..."
    @State private var userEmail: String = ""
    @State private var userPhone: String = ""
    @State private var userProfileImageURL: URL?

    // Stats State
    @State private var totalTours: Int = 0
    @State private var totalShows: Int = 0
    @State private var totalTicketsSold: Int = 0
    
    @State private var isLoading = true

    var body: some View {
        ZStack {
            // Background Gradient for iOS
            #if os(iOS)
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0/255, green: 58/255, blue: 83/255), Color(red: 23/255, green: 17/255, blue: 17/255)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            #endif
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    #if os(macOS)
                    Text("Account")
                        .font(.largeTitle.bold())
                    #endif

                    accountCard
                    
                    statsSection
                    
                    supportSection

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Account")
            #if os(iOS)
            .background(Color.clear)
            #endif
        }
        .onAppear {
            Task {
                await loadAllUserData()
            }
        }
    }

    // MARK: - Main UI Sections

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                KFImage(userProfileImageURL)
                    .placeholder {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(userName)
                        .font(.title2.bold())
                    Text("userid: \(appState.userID ?? "N/A")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label(userEmail, systemImage: "envelope.fill")
                Label(userPhone.isEmpty ? "No phone number" : userPhone, systemImage: "phone.fill")
            }
            .font(.subheadline)
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                   Text("encore indie")
                       .font(.headline.bold())
                   Button("Upgrade") {}
                        .font(.caption.bold())
                        .foregroundColor(.accentColor)
                }
                Spacer()
                HStack {
                    Circle()
                        .fill(syncManager.isOnline ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text("Online")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(16)
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stats")
                .font(.title2.bold())
            
            // Use a vertical layout for stats on iOS
            VStack(spacing: 12) {
                statBlock(count: totalTours, label: "Tours", icon: "airplane")
                statBlock(count: totalShows, label: "Shows", icon: "music.mic")
                statBlock(count: totalTicketsSold, label: "Tickets Sold", icon: "ticket.fill")
            }
        }
    }

    private func statBlock(count: Int, label: String, icon: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(count)")
                    .font(.system(size: 28, weight: .bold))
                Text(label)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Support")
                .font(.title2.bold())
            
            VStack(spacing: 12) {
                supportButton(title: "Contact Support") {}
                supportButton(title: "Terms of Service") {}
                supportButton(title: "Privacy Policy") {}
            }
            
            supportButton(title: "Clear Local Cache") {}
                .padding(.top)
            
            Button("Sign Out", role: .destructive) {
                AuthManager.shared.signOut()
            }
            .buttonStyle(PrimaryButtonStyle(color: .red.opacity(0.7)))
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
        }
    }

    private func supportButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 10)
                .background(.thinMaterial)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data Loading Logic

    private func loadAllUserData() async {
        guard let userID = appState.userID else {
            isLoading = false
            return
        }

        isLoading = true
        let db = Firestore.firestore()

        async let userProfileTask = db.collection("users").document(userID).getDocument()
        async let toursTask = db.collection("tours").whereField("ownerId", isEqualTo: userID).getDocuments()

        do {
            let userDocument = try await userProfileTask
            if let userData = userDocument.data() {
                await MainActor.run {
                    self.userName = userData["displayName"] as? String ?? "No Name"
                    self.userEmail = userData["email"] as? String ?? ""
                    self.userPhone = userData["phone"] as? String ?? ""
                    if let urlString = userData["profileImageURL"] as? String {
                        self.userProfileImageURL = URL(string: urlString)
                    }
                }
            }

            let toursSnapshot = try await toursTask
            let tourIDs = toursSnapshot.documents.compactMap { $0.documentID }
            await MainActor.run { self.totalTours = tourIDs.count }

            if !tourIDs.isEmpty {
                await fetchStats(for: tourIDs, db: db)
            } else {
                await MainActor.run { isLoading = false }
            }

        } catch {
            print("Error loading user data: \(error.localizedDescription)")
            await MainActor.run { isLoading = false }
        }
    }
    
    private func fetchStats(for tourIDs: [String], db: Firestore) async {
        async let showsTask = db.collection("shows").whereField("tourId", in: tourIDs).getDocuments()
        async let ticketedEventsTask = db.collection("ticketedEvents").whereField("tourId", in: tourIDs).getDocuments()

        do {
            let showsSnapshot = try await showsTask
            await MainActor.run { self.totalShows = showsSnapshot.count }
            
            let ticketedEventsSnapshot = try await ticketedEventsTask
            let eventIDs = ticketedEventsSnapshot.documents.compactMap { $0.documentID }

            if !eventIDs.isEmpty {
                let salesSnapshot = try await db.collection("ticketSales").whereField("ticketedEventId", in: eventIDs).getDocuments()
                let totalSold = salesSnapshot.documents.reduce(0) { $0 + ($1.data()["quantity"] as? Int ?? 0) }
                await MainActor.run { self.totalTicketsSold = totalSold }
            }
        } catch {
            print("Error fetching stats: \(error.localizedDescription)")
        }
        
        await MainActor.run { isLoading = false }
    }
}
