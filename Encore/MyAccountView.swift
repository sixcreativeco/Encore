import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MyAccountView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var overrideColorScheme: ColorScheme? = nil
    @State private var isDarkMode: Bool = false
    @State private var totalTours: Int = 0
    @State private var totalShows: Int = 0
    @State private var totalFlights: Int = 0
    @State private var userEmail: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {

                accountInfoSection
                preferencesSection
                usageStatsSection
                supportSection
                devToolsSection
                versionSection

            }
            .padding()
            .onAppear {
                loadStats()
                loadUserEmail()
            }
        }
        .navigationTitle("My Account")
    }

    // MARK: - Account Info

    private var accountInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account")
                .font(.title2.bold())

            HStack(alignment: .center) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    if !userEmail.isEmpty {
                        Text(userEmail)
                            .font(.headline)
                    }

                    Text("User ID: \(appState.userID ?? "Unknown")")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("Online Status: \(OfflineSyncManager.shared.isOnline ? "Online" : "Offline")")
                        .font(.subheadline)
                        .foregroundColor(OfflineSyncManager.shared.isOnline ? .green : .gray)
                }

                Spacer()

                Button("Sign Out", role: .destructive) {
                    signOut()
                }
                .font(.headline)
                .foregroundColor(.red)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferences")
                .font(.title2.bold())

            Toggle("Dark Mode", isOn: $isDarkMode)
                .onChange(of: isDarkMode) { value in
                    overrideColorScheme = value ? .dark : .light
                }
        }
    }

    // MARK: - Usage Stats

    private var usageStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage Stats")
                .font(.title2.bold())

            HStack {
                statBlock(label: "Tours", count: totalTours)
                statBlock(label: "Shows", count: totalShows)
                statBlock(label: "Flights", count: totalFlights)
            }
        }
    }

    private func statBlock(label: String, count: Int) -> some View {
        VStack {
            Text("\(count)")
                .font(.title)
                .bold()
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Support

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Support")
                .font(.title2.bold())

            Button("Contact Support") { }
            Button("Privacy Policy") { }
            Button("Terms of Service") { }
        }
    }

    // MARK: - Dev Tools

    private var devToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Developer Tools")
                .font(.title2.bold())

            Button(role: .destructive) {
                // Add wipe cache logic here
            } label: {
                Text("Wipe Local Cache")
            }
        }
    }

    // MARK: - Version (added below dev tools)

    private var versionSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("App Version: 1.7.3")
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }

    // MARK: - Load Stats Logic

    private func loadStats() {
        guard let userID = appState.userID else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("tours").getDocuments { snapshot, _ in
            self.totalTours = snapshot?.documents.count ?? 0

            var showCount = 0
            var flightCount = 0

            let group = DispatchGroup()

            snapshot?.documents.forEach { tourDoc in
                group.enter()
                db.collection("users").document(userID).collection("tours").document(tourDoc.documentID).collection("shows").getDocuments { showSnapshot, _ in
                    showCount += showSnapshot?.documents.count ?? 0
                    group.leave()
                }

                group.enter()
                db.collection("users").document(userID).collection("tours").document(tourDoc.documentID).collection("flights").getDocuments { flightSnapshot, _ in
                    flightCount += flightSnapshot?.documents.count ?? 0
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.totalShows = showCount
                self.totalFlights = flightCount
            }
        }
    }

    // MARK: - Load User Email

    private func loadUserEmail() {
        if let currentUser = Auth.auth().currentUser {
            self.userEmail = currentUser.email ?? ""
        }
    }

    // MARK: - Sign Out Logic

    private func signOut() {
        appState.userID = nil
        appState.selectedTour = nil
        appState.selectedShow = nil
    }
}
