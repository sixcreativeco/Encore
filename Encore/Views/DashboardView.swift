import SwiftUI
import Kingfisher
import FirebaseFirestore

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
    @State private var isShowingBroadcastView = false
    @State private var expandedItemID: String? = nil

    private var compactDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }

    var body: some View {
        ZStack {
            // Background for iOS
            #if os(iOS)
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0/255, green: 58/255, blue: 83/255), Color(red: 23/255, green: 17/255, blue: 17/255)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            #endif

            // Main Content
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
                #if os(macOS)
                .padding(30)
                #else
                .padding()
                #endif
            }
            #if os(iOS)
            .background(Color.clear)
            #endif
        }
        .task {
            await loadDashboardData()
        }
        .onChange(of: appState.tours) {
            Task {
                await loadDashboardData()
            }
        }
        .sheet(isPresented: $showAddShowView) {
            if let tour = currentTour {
                AddShowView(tourID: tour.id ?? "", userID: tour.ownerId, artistName: tour.artist, onSave: {})
            }
        }
        .sheet(isPresented: $isShowingBroadcastView) {
            if let tour = currentTour {
                BroadcastView(tour: tour)
            }
        }
    }

    // MARK: - Main UI Sections

    private var header: some View {
        #if os(macOS)
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
        #else
        EmptyView()
        #endif
    }

    private var topPanels: some View {
        #if os(macOS)
        HStack(alignment: .top, spacing: 24) {
            todaySection
                .frame(maxWidth: 450)

            if let tour = currentTour {
                currentTourSection(tour: tour)
            } else {
                noCurrentTourPlaceholder
            }
        }
        .frame(minHeight: 350)
        #else
        VStack(alignment: .leading, spacing: 24) {
            if let tour = currentTour {
                currentTourSection(tour: tour)
            } else {
                noCurrentTourPlaceholder
            }
            todaySection
        }
        #endif
    }

    @ViewBuilder
    private var sharedWithYouSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shared With Me")
                .font(.title2.bold())
                .padding(.horizontal)
                .padding(.top)

            if sharedTours.isEmpty {
                Text("No other tours have been shared with you.")
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
            
            #if os(macOS)
            HStack(alignment: .bottom, spacing: 16) {
                DashboardTourCard(posterURL: tour.posterURL)

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
                        
                        if appState.userID == tour.ownerId {
                            Button(action: { isShowingBroadcastView = true }) {
                                Text("Broadcast")
                                    .fontWeight(.semibold)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.accentColor.opacity(0.8))
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
                }
                .frame(height: 270)
            }
            .padding()
            .background(Color.black.opacity(0.15))
            .cornerRadius(12)
            #else
            HStack(alignment: .top, spacing: 16) {
                DashboardTourCard(posterURL: tour.posterURL)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(tour.tourName)
                        .font(.system(size: 20, weight: .bold))

                    Label(tour.artist, systemImage: "music.mic")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Label("\(totalShows) Shows", systemImage: "music.note.list")
                    .font(.caption)
                    .foregroundColor(.secondary)

                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: { appState.selectedTour = tour }) {
                            Text("Go to tour")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }.buttonStyle(.plain)
                        
                        if appState.userID == tour.ownerId {
                            Button(action: { isShowingBroadcastView = true }) {
                                Text("Broadcast")
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.accentColor.opacity(0.8))
                                    .cornerRadius(8)
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
            .background(Color.black.opacity(0.15))
            .cornerRadius(12)
            #endif
        }
    }
    
    private struct DashboardTourCard: View {
        let posterURL: String?
        var body: some View {
            KFImage(URL(string: posterURL ?? ""))
                .placeholder { ZStack { Color.gray.opacity(0.1); Image(systemName: "photo") } }
                .resizable()
                .scaledToFill()
                .frame(width: 180, height: 270)
                .clipped()
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

    private func loadDashboardData() async {
        await MainActor.run { isLoading = true }

        let now = Date()
        let foundTour = appState.tours.first { tour in
            let start = tour.startDate.dateValue()
            let end = tour.endDate.dateValue()
            if Calendar.current.isDate(start, inSameDayAs: end) {
                return Calendar.current.isDate(now, inSameDayAs: start)
            }
            return (start...end).contains(now)
        }

        await MainActor.run { self.currentTour = foundTour }

        if let tour = foundTour, let tourID = tour.id {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadTodayItems(tourID: tourID) }
                group.addTask { await self.loadExtraTourDetails(tourID: tourID) }
            }
        }
        
        await MainActor.run {
            self.sharedTours = appState.tours.filter { $0.id != self.currentTour?.id }
            self.isLoading = false
        }
    }
    
    private func loadExtraTourDetails(tourID: String) async {
        let db = Firestore.firestore()
        
        async let managerTask = db.collection("tourCrew")
            .whereField("tourId", isEqualTo: tourID)
            .whereField("roles", arrayContains: "Tour Manager")
            .limit(to: 1)
            .getDocuments()

        async let showsTask = db.collection("shows")
            .whereField("tourId", isEqualTo: tourID)
            .getDocuments()

        do {
            let managerSnapshot = try await managerTask
            if let doc = managerSnapshot.documents.first, let crewMember = try? doc.data(as: TourCrew.self) {
                await MainActor.run { self.tourManagerName = crewMember.name }
            } else {
                await MainActor.run { self.tourManagerName = "Not Assigned" }
            }
        } catch {
            print("Error fetching tour manager: \(error.localizedDescription)")
            await MainActor.run { self.tourManagerName = "Not Assigned" }
        }
        
        do {
            let showsSnapshot = try await showsTask
            await MainActor.run { self.totalShows = showsSnapshot.count }
        } catch {
            print("Error fetching show count: \(error.localizedDescription)")
            await MainActor.run { self.totalShows = 0 }
        }
    }
    
    private func loadTodayItems(tourID: String) async {
        let db = Firestore.firestore()
        
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        
        do {
            let snapshot = try await db.collection("itineraryItems")
                .whereField("tourId", isEqualTo: tourID)
                .whereField("timeUTC", isGreaterThanOrEqualTo: Timestamp(date: startOfToday))
                .whereField("timeUTC", isLessThan: Timestamp(date: startOfTomorrow))
                .getDocuments()
            
            let items = snapshot.documents.compactMap { try? $0.data(as: ItineraryItem.self) }
            await MainActor.run {
                self.todayItems = items.sorted(by: { $0.timeUTC.dateValue() < $1.timeUTC.dateValue() })
            }
        } catch {
            print("Error fetching today's items: \(error.localizedDescription)")
            await MainActor.run { self.todayItems = [] }
        }
    }
}
