import SwiftUI
import FirebaseFirestore
import Kingfisher

struct DashboardView: View {
    @EnvironmentObject var appState: AppState

    // State for data
    @State private var todayItems: [ItineraryItem] = []
    @State private var currentTour: Tour?
    @State private var sharedTours: [Tour] = []
    @State private var tourManagerName: String = "Not Assigned"
    @State private var totalShows: Int = 0

    // View State
    @State private var isLoading = true
    @State private var showAddShowView = false
    @State private var expandedItemID: String? = nil

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
        .sheet(isPresented: $showAddShowView) {
            if let tour = currentTour {
                AddShowView(tourID: tour.id ?? "", userID: tour.ownerId, artistName: tour.artist, onSave: {})
            }
        }
    }

    // MARK: - Main UI Sections

    private var header: some View {
        HStack {
            Text("Dashboard").font(.largeTitle.bold())
            Spacer()
            Button(action: {
                 appState.selectedTab = "NewTour"
            }) {
                Image(systemName: "plus")
                    .fontWeight(.semibold).foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.15)).clipShape(Circle())
            }.buttonStyle(.plain)
        }
    }

    private var topPanels: some View {
        HStack(alignment: .top, spacing: 24) {
            todaySection
                .frame(maxWidth: 450) // Constrain the width of the Today section

            if let tour = currentTour {
                currentTourSection(tour: tour)
            } else {
                noCurrentTourPlaceholder
            }
        }
        .frame(minHeight: 350)
    }

    @ViewBuilder
    private var sharedWithYouSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shared With Me")
                .font(.title2.bold())
                .padding(.horizontal)
                .padding(.top)

            if sharedTours.isEmpty {
                Text("No tours have been shared with you.")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .center)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(sharedTours) { tour in
                            Button(action: {
                                appState.selectedTour = tour
                            }) {
                                TourCard(tour: tour)
                            }.buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .background(Color.black.opacity(0.15))
        .cornerRadius(12)
    }

    // MARK: - Panel Subviews
    
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today").font(.title2.bold())
            if todayItems.isEmpty {
                Text("No events scheduled for today.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 300, alignment: .center)
                    .background(Color.black.opacity(0.15))
                    .cornerRadius(12)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(todayItems) { item in
                            ItineraryItemCard(
                                item: item,
                                isExpanded: expandedItemID == item.id,
                                onExpandToggle: { toggleExpanded(item) },
                                onEdit: {},
                                onDelete: {}
                            )
                        }
                    }
                }
                .frame(height: 300)
            }
        }
    }

    private func toggleExpanded(_ item: ItineraryItem) {
        withAnimation {
            expandedItemID = (expandedItemID == item.id) ? nil : item.id
        }
    }
    
    private func currentTourSection(tour: Tour) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Tour").font(.title2.bold())
            
            HStack(alignment: .bottom, spacing: 16) {
                 DashboardTourCard(posterURL: tour.posterURL)
                    .frame(width: 180)

                VStack(alignment: .leading, spacing: 12) {
                    Text(tour.tourName)
                        .font(.system(size: 32, weight: .bold))

                    VStack(alignment: .leading, spacing: 8) {
                        Label { Text(tour.artist) } icon: { Image(systemName: "music.mic") }
                        Label { Text("\(compactDateFormatter.string(from: tour.startDate.dateValue())) - \(compactDateFormatter.string(from: tour.endDate.dateValue()))") } icon: { Image(systemName: "calendar") }
                        Label { Text("Tour Manager: \(tourManagerName)") } icon: { Image(systemName: "person.fill") }
                        Label { Text("Shows: \(totalShows)") } icon: { Image(systemName: "music.note.list") }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Button(action: { appState.selectedTour = tour }) {
                            Text("Go to tour")
                                .fontWeight(.semibold)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }.buttonStyle(.plain)
                        
                        Button(action: { showAddShowView = true }) {
                            Text("Add Show")
                                .fontWeight(.semibold)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }.buttonStyle(.plain)
                    }
                }
                .frame(height: 270)
            }
            .padding()
            .background(Color.black.opacity(0.15))
            .cornerRadius(12)
        }
    }
    
    private struct DashboardTourCard: View {
        let posterURL: String?
        var body: some View {
            KFImage(URL(string: posterURL ?? ""))
                .placeholder { ZStack { Color.gray.opacity(0.1); Image(systemName: "photo") } }
                .resizable()
                .aspectRatio(2/3, contentMode: .fit)
                .cornerRadius(8)
        }
    }
    
    private var noCurrentTourPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Tour").font(.title2.bold())
            Text("No tour is currently active.")
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 300, alignment: .center)
                .background(Color.black.opacity(0.15))
                .cornerRadius(12)
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
            if let activeTour = tour, let tourID = activeTour.id {
                loadTourDetails(tourID: tourID)
                
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
    
    private func loadTodayItems(tourID: String, completion: @escaping ([ItineraryItem]) -> Void) {
        let db = Firestore.firestore()
        
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        
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
            
            let tourIDs = documents.map { $0.documentID }
            
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

    private func loadTourDetails(tourID: String) {
        let db = Firestore.firestore()
        
        db.collection("tourCrew")
            .whereField("tourId", isEqualTo: tourID)
            .whereField("roles", arrayContains: "Tour Manager")
            .limit(to: 1)
            .getDocuments { snapshot, _ in
                if let doc = snapshot?.documents.first, let crewMember = try? doc.data(as: TourCrew.self) {
                    self.tourManagerName = crewMember.name
                } else {
                    self.tourManagerName = "Not Assigned"
                }
            }

        db.collection("shows")
            .whereField("tourId", isEqualTo: tourID)
            .getDocuments { snapshot, _ in
                self.totalShows = snapshot?.documents.count ?? 0
            }
    }
}
