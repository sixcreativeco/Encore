import SwiftUI
import FirebaseFirestore
import Kingfisher

struct DashboardView: View {
    @EnvironmentObject var appState: AppState

    // FIX: State variables now use the new, simple model types.
    @State private var todayItems: [ItineraryItem] = []
    @State private var currentTour: Tour?
    @State private var sharedTours: [Tour] = []
    
    @State private var isLoading = true

    private var compactDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                
                if isLoading {
                    ProgressView("Loading Dashboard...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 100)
                } else {
                    topPanels
                    sharedWithYouSection
                }
            }
            .padding(30)
        }
        .onAppear(perform: loadDashboardData)
    }

    // MARK: - Main UI Sections

    private var header: some View {
        HStack {
            Text("Dashboard").font(.largeTitle.bold())
            Spacer()
            Button(action: {}) {
                Image(systemName: "plus")
                    .fontWeight(.semibold).foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color(nsColor: .controlBackgroundColor)).clipShape(Circle())
            }.buttonStyle(.plain)
        }
    }

    private var topPanels: some View {
        HStack(alignment: .top, spacing: 24) {
            todaySection.layoutPriority(1)
            if let tour = currentTour {
                currentTourSection(tour: tour).layoutPriority(1)
            } else {
                noCurrentTourPlaceholder
            }
        }
    }

    @ViewBuilder
    private var sharedWithYouSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shared With Me").font(.title2.bold())
            if sharedTours.isEmpty {
                Text("No tours have been shared with you.").foregroundColor(.secondary).padding()
                    .frame(maxWidth: .infinity, alignment: .center).background(Color(nsColor: .controlBackgroundColor)).cornerRadius(12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(sharedTours) { tour in
                            Button(action: {
                                // This will need to be updated once AppState uses the new Tour model
                                // appState.selectedTour = tour
                            }) {
                                // This will use a new TourCard view we'll create next
                                // For now, a placeholder
                                Text(tour.tourName).padding().background(Color.blue).foregroundColor(.white).cornerRadius(8)
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
        }.padding(.top)
    }

    // MARK: - Panel Subviews
    
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today").font(.title2.bold())
            if todayItems.isEmpty {
                Text("No events scheduled for today.").font(.subheadline).foregroundColor(.secondary).padding()
                    .frame(maxWidth: .infinity, minHeight: 150).background(Color(nsColor: .controlBackgroundColor)).cornerRadius(12)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(todayItems) { item in
                            // This will use a new ItineraryCard view we'll create next
                            // For now, a placeholder
                            Text(item.title).padding().frame(maxWidth: .infinity, alignment: .leading).background(Color.gray.opacity(0.1)).cornerRadius(8)
                        }
                    }
                }
                .frame(height: 300)
            }
        }
    }
    
    private func currentTourSection(tour: Tour) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Tour").font(.title2.bold())
            HStack(spacing: 16) {
                DashboardTourCard(posterURL: tour.posterURL)
                    .frame(width: 180)
                
                VStack(alignment: .leading, spacing: 8) {
                    // FIX: Using new property name `tourName`
                    Text(tour.tourName).font(.title3.bold())
                    Text(tour.artist).font(.subheadline).foregroundColor(.secondary)
                    // FIX: Using .dateValue() on the Timestamps
                    Text("\(compactDateFormatter.string(from: tour.startDate.dateValue())) - \(compactDateFormatter.string(from: tour.endDate.dateValue()))")
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                    // This will need to be updated once AppState uses the new Tour model
                    // StyledButtonV2(title: "Go to tour", action: { appState.selectedTour = tour })
                    // StyledButtonV2(title: "Add Show", action: {})
                }
            }
            .padding().background(Color(nsColor: .controlBackgroundColor)).cornerRadius(12)
        }
    }
    
    private struct DashboardTourCard: View {
        let posterURL: String?
        var body: some View {
            KFImage(URL(string: posterURL ?? ""))
                .placeholder { ZStack { Color.gray.opacity(0.1); Image(systemName: "photo") } }
                .resizable().scaledToFill()
                .frame(width: 180).aspectRatio(2/3, contentMode: .fit).cornerRadius(8)
        }
    }
    
    private var noCurrentTourPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Tour").font(.title2.bold())
            Text("No tour is currently active.").foregroundColor(.secondary).padding()
                .frame(maxWidth: .infinity, minHeight: 150).background(Color(nsColor: .controlBackgroundColor)).cornerRadius(12)
        }
    }

    // MARK: - Data Loading (HEAVILY REFACTORED)

    private func loadDashboardData() {
        guard let userID = appState.userID else { return }
        self.isLoading = true
        
        let group = DispatchGroup()
        
        group.enter()
        loadCurrentTour(userID: userID) { tour in
            self.currentTour = tour
            if let activeTour = tour, let tourID = activeTour.id {
                self.loadTodayItems(tourID: tourID) { items in
                    self.todayItems = items.sorted(by: { $0.timeUTC.dateValue() < $1.timeUTC.dateValue() })
                    group.leave()
                }
            } else {
                self.todayItems = []
                group.leave()
            }
        }
        
        group.enter()
        loadSharedTours(userID: userID) { tours in
            self.sharedTours = tours
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
    
    private func loadCurrentTour(userID: String, completion: @escaping (Tour?) -> Void) {
        let db = Firestore.firestore()
        let now = Timestamp(date: Date())
        
        // Query the new top-level /tours collection
        db.collection("tours")
            .whereField("ownerId", isEqualTo: userID)
            .whereField("startDate", isLessThanOrEqualTo: now)
            .getDocuments { snapshot, _ in
                let activeTours = snapshot?.documents
                    .compactMap { try? $0.data(as: Tour.self) }
                    .filter { $0.endDate >= now }
                completion(activeTours?.first)
            }
    }
    
    // Massively simplified function
    private func loadTodayItems(tourID: String, completion: @escaping ([ItineraryItem]) -> Void) {
        let db = Firestore.firestore()
        
        // Define the time range for "Today"
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        
        // A single, simple query to the top-level /itineraryItems collection
        db.collection("itineraryItems")
            .whereField("tourId", isEqualTo: tourID)
            .whereField("timeUTC", isGreaterThanOrEqualTo: Timestamp(date: startOfToday))
            .whereField("timeUTC", isLessThan: Timestamp(date: startOfTomorrow))
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching today's items: \(error?.localizedDescription ?? "Unknown")")
                    completion([])
                    return
                }
                let items = documents.compactMap { try? $0.data(as: ItineraryItem.self) }
                completion(items)
            }
    }
    
    private func loadSharedTours(userID: String, completion: @escaping ([Tour]) -> Void) {
        let db = Firestore.firestore()
        let sharedToursRef = db.collection("users").document(userID).collection("sharedTours")
        
        sharedToursRef.getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                completion([])
                return
            }
            
            // Get all the IDs of the tours shared with the user
            let tourIDs = documents.map { $0.documentID }
            
            // Fetch all those tours in a single, efficient query from the top-level /tours collection
            db.collection("tours").whereField(FieldPath.documentID(), in: tourIDs)
                .getDocuments { tourSnapshot, error in
                    guard let tourDocuments = tourSnapshot?.documents else {
                        completion([])
                        return
                    }
                    let tours = tourDocuments.compactMap { try? $0.data(as: Tour.self) }
                    completion(tours)
                }
        }
    }
}
