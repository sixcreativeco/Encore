import SwiftUI
import FirebaseFirestore
import Kingfisher

struct DashboardView: View {
    @EnvironmentObject var appState: AppState

    // State for data fetched for the dashboard
    @State private var todayItems: [ItineraryItemModel] = []
    @State private var currentTour: TourModel?
    @State private var sharedTours: [TourModel] = []
    
    @State private var isLoading = true

    private var compactDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM" // e.g., "16 Jun"
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
                            Button(action: { appState.selectedTour = tour }) {
                                TourCard(tour: tour)
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
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
            } else {
                // FIX: Wrapped the list of cards in a ScrollView and gave it a fixed height.
                ScrollView {
                    VStack(spacing: 10) {
                        // FIX: Removed .prefix(4) to show all of today's items.
                        ForEach(todayItems) { item in
                            ItineraryItemCard(item: item, isExpanded: false, onExpandToggle: {}, onEdit: {}, onDelete: {})
                        }
                    }
                }
                // You can adjust this height to whatever you like.
                .frame(height: 300)
            }
        }
    }
    
    private func currentTourSection(tour: TourModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Tour").font(.title2.bold())
            HStack(spacing: 16) {
                DashboardTourCard(posterURL: tour.posterURL)
                    .frame(width: 180)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(tour.name).font(.title3.bold())
                    Text(tour.artist).font(.subheadline).foregroundColor(.secondary)
                    Text("\(compactDateFormatter.string(from: tour.startDate)) - \(compactDateFormatter.string(from: tour.endDate))")
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                    StyledButtonV2(title: "Go to tour", action: { appState.selectedTour = tour })
                    StyledButtonV2(title: "Add Show", action: {})
                }
            }
            .padding().background(Color(nsColor: .controlBackgroundColor)).cornerRadius(12)
        }
    }
    
    private struct DashboardTourCard: View {
        let posterURL: String?
        var body: some View {
            KFImage(URL(string: posterURL ?? ""))
                .placeholder {
                    ZStack {
                        Color.gray.opacity(0.1)
                        Image(systemName: "photo").foregroundColor(.gray).font(.system(size: 24))
                    }
                }
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

    // MARK: - Data Loading

    private func loadDashboardData() {
        guard let userID = appState.userID else { return }
        self.isLoading = true
        let group = DispatchGroup()
        
        group.enter()
        loadCurrentTour(userID: userID) { tour in
            self.currentTour = tour
            if let activeTour = tour {
                loadTodayItems(userID: userID, tourID: activeTour.id) { items in
                    self.todayItems = items.sorted(by: { $0.time < $1.time })
                    group.leave()
                }
            } else {
                self.todayItems = []
                group.leave()
            }
        }
        
        group.enter()
        loadSharedTours(userID: userID) { tours in self.sharedTours = tours; group.leave() }
        
        group.notify(queue: .main) { self.isLoading = false }
    }
    
    private func loadCurrentTour(userID: String, completion: @escaping (TourModel?) -> Void) {
        let db = Firestore.firestore(); let now = Date()
        db.collection("users").document(userID).collection("tours")
            .whereField("startDate", isLessThanOrEqualTo: now)
            .getDocuments { snapshot, _ in
                let activeTours = snapshot?.documents.compactMap { TourModel(from: $0, ownerUserID: userID) }.filter { $0.endDate >= now }
                completion(activeTours?.first)
            }
    }
    
    private func loadTodayItems(userID: String, tourID: String, completion: @escaping ([ItineraryItemModel]) -> Void) {
        let db = Firestore.firestore()
        let tourRef = db.collection("users").document(userID).collection("tours").document(tourID)
        let group = DispatchGroup()
        var allItems: [ItineraryItemModel] = []
        
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        group.enter()
        tourRef.collection("itinerary")
            .whereField("time", isGreaterThanOrEqualTo: startOfToday)
            .whereField("time", isLessThan: startOfTomorrow)
            .getDocuments { snapshot, _ in
                let items = snapshot?.documents.compactMap { ItineraryItemModel(from: $0) } ?? []
                allItems.append(contentsOf: items)
                group.leave()
            }
        
        group.enter()
        tourRef.collection("flights")
            .whereField("departureTime", isGreaterThanOrEqualTo: startOfToday)
            .whereField("departureTime", isLessThan: startOfTomorrow)
            .getDocuments { snapshot, _ in
                let flights = snapshot?.documents.compactMap { FlightModel(from: $0)?.toItineraryItem() } ?? []
                allItems.append(contentsOf: flights)
                group.leave()
            }
        
        group.enter()
        tourRef.collection("shows")
            .whereField("date", isGreaterThanOrEqualTo: startOfToday)
            .whereField("date", isLessThan: startOfTomorrow)
            .getDocuments { snapshot, _ in
                let shows = snapshot?.documents.compactMap { ShowModel(from: $0) } ?? []
                for show in shows {
                    if let time = show.loadIn { allItems.append(ItineraryItemModel(type: .loadIn, title: "Load In", time: time, subtitle: show.venue)) }
                    if let time = show.soundCheck { allItems.append(ItineraryItemModel(type: .soundcheck, title: "Soundcheck", time: time, subtitle: show.venue)) }
                    if let time = show.doorsOpen { allItems.append(ItineraryItemModel(type: .doors, title: "Doors Open", time: time, subtitle: show.venue)) }
                    if let setTime = show.headliner?.setTime { allItems.append(ItineraryItemModel(type: .headline, title: "Headliner Set", time: setTime, subtitle: show.venue)) }
                }
                group.leave()
            }
        
        group.notify(queue: .main) {
            completion(allItems)
        }
    }
    
    private func loadSharedTours(userID: String, completion: @escaping ([TourModel]) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("sharedTours").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else { completion([]); return }
            let group = DispatchGroup(); var results: [TourModel] = []
            guard !documents.isEmpty else { completion([]); return }
            for doc in documents {
                let ownerUserID = doc.data()["creatorUserID"] as? String ?? ""; let tourID = doc.documentID
                if ownerUserID.isEmpty { continue }
                group.enter()
                db.collection("users").document(ownerUserID).collection("tours").document(tourID).getDocument { tourDoc, _ in
                    if let tourDoc = tourDoc, let tour = TourModel(from: tourDoc, ownerUserID: ownerUserID) { results.append(tour) }
                    group.leave()
                }
            }
            group.notify(queue: .main) { completion(results) }
        }
    }
}
