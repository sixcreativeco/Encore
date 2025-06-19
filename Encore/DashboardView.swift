import SwiftUI
import FirebaseFirestore

struct DashboardView: View {
    @EnvironmentObject var appState: AppState

    // State for data fetched for the dashboard
    @State private var todayItems: [ItineraryItemModel] = []
    @State private var sharedTours: [TourModel] = []
    @State private var dbCounts: (contacts: Int, venues: Int, hotels: Int) = (0, 0, 0)
    
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // MARK: - Header
                HStack {
                    Text("Dashboard")
                        .font(.largeTitle.bold())
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "bell.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                if isLoading {
                    ProgressView("Loading Dashboard...")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                } else {
                    // MARK: - Today Section
                    todaySection
                    
                    // MARK: - Shared With You Section
                    sharedWithYouSection
                    
                    // MARK: - Database Overview Section
                    databaseOverviewSection
                }
            }
            .padding(30)
        }
        .onAppear(perform: loadDashboardData)
    }

    // MARK: - Subviews
    
    @ViewBuilder
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.title2.bold())
            
            if todayItems.isEmpty {
                Text("No events scheduled for today.")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
            } else {
                VStack(spacing: 10) {
                    ForEach(todayItems) { item in
                        // Using ItineraryItemCard as a compact representation
                        ItineraryItemCard(item: item, isExpanded: false, onExpandToggle: {}, onEdit: {}, onDelete: {})
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var sharedWithYouSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shared With You")
                .font(.title2.bold())
            
            if sharedTours.isEmpty {
                Text("No tours have been shared with you.")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(sharedTours) { tour in
                            Button(action: {
                                appState.selectedTour = tour
                            }) {
                                TourCard(tour: tour)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var databaseOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Database Overview")
                .font(.title2.bold())
            
            HStack(spacing: 16) {
                statBlock(count: dbCounts.contacts, label: "Contacts")
                statBlock(count: dbCounts.venues, label: "Venues")
                statBlock(count: dbCounts.hotels, label: "Hotels")
            }
        }
    }
    
    private func statBlock(count: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(count)")
                .font(.system(size: 32, weight: .bold))
            Text(label)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Data Loading
    
    private func loadDashboardData() {
        guard let userID = appState.userID else { return }
        self.isLoading = true
        
        let group = DispatchGroup()
        
        group.enter()
        loadTodayItems(userID: userID) { items in
            self.todayItems = items
            group.leave()
        }
        
        group.enter()
        loadSharedTours(userID: userID) { tours in
            self.sharedTours = tours
            group.leave()
        }
        
        group.enter()
        loadDatabaseCounts(userID: userID) { counts in
            self.dbCounts = counts
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
    
    private func loadTodayItems(userID: String, completion: @escaping ([ItineraryItemModel]) -> Void) {
        // This is a simplified fetch. A full implementation would check all active tours
        // for itinerary items on the current date.
        completion([]) // Returning empty for now as the logic is complex.
    }
    
    private func loadSharedTours(userID: String, completion: @escaping ([TourModel]) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("sharedTours").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                completion([])
                return
            }
            
            let group = DispatchGroup()
            var results: [TourModel] = []
            
            for doc in documents {
                let ownerUserID = doc.data()["creatorUserID"] as? String ?? ""
                let tourID = doc.documentID
                if ownerUserID.isEmpty { continue }
                
                group.enter()
                db.collection("users").document(ownerUserID).collection("tours").document(tourID).getDocument { tourDoc, _ in
                    if let tourDoc = tourDoc, let tour = TourModel(from: tourDoc, ownerUserID: ownerUserID) {
                        results.append(tour)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                completion(results)
            }
        }
    }
    
    private func loadDatabaseCounts(userID: String, completion: @escaping ((Int, Int, Int)) -> Void) {
        let db = Firestore.firestore()
        let group = DispatchGroup()
        
        var contactCount = 0
        var venueCount = 0
        var hotelCount = 0
        
        group.enter()
        db.collection("users").document(userID).collection("contacts").count.getAggregation(source: .server) { snapshot, _ in
            contactCount = Int(truncating: snapshot?.count ?? 0)
            group.leave()
        }
        
        group.enter()
        db.collection("users").document(userID).collection("venues").count.getAggregation(source: .server) { snapshot, _ in
            venueCount = Int(truncating: snapshot?.count ?? 0)
            group.leave()
        }
        
        group.enter()
        db.collection("users").document(userID).collection("hotels").count.getAggregation(source: .server) { snapshot, _ in
            hotelCount = Int(truncating: snapshot?.count ?? 0)
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion((contactCount, venueCount, hotelCount))
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(AppState())
    }
}
