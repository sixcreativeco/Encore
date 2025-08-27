import SwiftUI
import Kingfisher
import FirebaseAuth
import FirebaseFirestore

struct TourListView: View {
    @EnvironmentObject var appState: AppState
    
    var onTourSelected: ((Tour) -> Void)? = nil
    
    @State private var isShowingTutorial = false

    private var upcomingTours: [Tour] {
        let today = Calendar.current.startOfDay(for: Date())
        return appState.tours.filter { $0.startDate.dateValue() > today }
    }

    private var currentTours: [Tour] {
        let today = Calendar.current.startOfDay(for: Date())
        return appState.tours.filter { $0.startDate.dateValue() <= today && $0.endDate.dateValue() >= today }
    }

    private var pastTours: [Tour] {
        let today = Calendar.current.startOfDay(for: Date())
        return appState.tours.filter { $0.endDate.dateValue() < today }.sorted { $0.endDate.dateValue() > $1.endDate.dateValue() }
    }

    var body: some View {
        ZStack {
            #if os(iOS)
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0/255, green: 58/255, blue: 83/255), Color(red: 23/255, green: 17/255, blue: 17/255)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            #endif

            if appState.tours.isEmpty {
                emptyStateView
            } else {
                tourScrollView
            }
        }
        .onAppear {
            appState.loadTours()
            preloadPosterImages(for: appState.tours)
            
            if appState.shouldShowTourCreationTutorial {
                isShowingTutorial = true
            }
        }
        .sheet(isPresented: $isShowingTutorial) {
            // --- FIX IS HERE ---
            // The closure now accepts the 'shouldPersist' boolean parameter.
            FeatureTutorialView { shouldPersist in
                isShowingTutorial = false
                appState.shouldShowTourCreationTutorial = false
                
                if let userID = appState.userID, shouldPersist {
                    FirebaseUserService.shared.markTourCreationTutorialAsCompleted(for: userID)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "music.mic.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No tours yet")
                    .font(.title2.bold())
                Text("Get started by creating your first tour.")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                appState.selectedTab = "NewTour"
            }) {
                Text("Create a tour")
                    .fontWeight(.semibold)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var tourScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                #if os(macOS)
                HStack {
                    Text("Tours")
                        .font(.largeTitle.bold())
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
                .padding(.horizontal)
                #endif

                if !currentTours.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Tour")
                            .font(.title.bold())
                            .padding(.horizontal)
                    
                        ForEach(currentTours) { tour in
                            CurrentTourCard(tour: tour, onTourSelected: onTourSelected)
                                .padding(.horizontal)
                        }
                    }
                }

                if !upcomingTours.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming")
                            .font(.title2.bold())
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(upcomingTours) { tour in
                                    Button(action: { onTourSelected?(tour) }) {
                                        TourCard(tour: tour)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                if !pastTours.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Past Tours")
                            .font(.title2.bold())
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(pastTours) { tour in
                                    Button(action: { onTourSelected?(tour) }) {
                                        TourCard(tour: tour)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        #if os(iOS)
        .background(Color.clear)
        #endif
    }

    private func preloadPosterImages(for tours: [Tour]) {
        let urls = tours.compactMap { URL(string: $0.posterURL ?? "") }
        ImagePrefetcher(urls: urls).start()
    }
}

fileprivate struct CurrentTourCard: View {
    let tour: Tour
    var onTourSelected: ((Tour) -> Void)?
    @State private var tourManagerName: String?
    @State private var showCount: Int = 0
    @State private var crewCount: Int = 0

    private var compactDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            KFImage(URL(string: tour.posterURL ?? ""))
                .placeholder { Color.gray.opacity(0.1) }
                .resizable()
                .aspectRatio(contentMode: .fill)
                #if os(macOS)
                .frame(width: 130, height: 195)
                #else
                .frame(width: 100, height: 150)
                #endif
                .cornerRadius(8)

            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 8) {
                    #if os(macOS)
                    Text(tour.artist.uppercased())
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .tracking(1.5)
                    #endif
                    
                    Text(tour.tourName)
                        .font(.system(size: 22, weight: .bold))

                    Label("\(compactDateFormatter.string(from: tour.startDate.dateValue())) - \(compactDateFormatter.string(from: tour.endDate.dateValue()))", systemImage: "calendar")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    if let tourManagerName = tourManagerName {
                        Label(tourManagerName, systemImage: "person.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    Label("\(showCount) Shows", systemImage: "music.mic")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Label("\(crewCount) Crew Members", systemImage: "person.3.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.top, 5)

                Spacer()

                HStack {
                    Button(action: {
                        onTourSelected?(tour)
                    }) {
                        Text("Go to tour")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.25))
        .cornerRadius(16)
        .task {
            await fetchExtraTourInfo()
        }
    }

    private func fetchExtraTourInfo() async {
        guard let tourID = tour.id else { return }
        let db = Firestore.firestore()
        
        async let managerTask = db.collection("tourCrew")
            .whereField("tourId", isEqualTo: tourID)
            .whereField("roles", arrayContains: "Tour Manager")
            .limit(to: 1).getDocuments()

        async let showCountTask = db.collection("shows")
            .whereField("tourId", isEqualTo: tourID)
            .count.getAggregation(source: .server)

        async let crewCountTask = db.collection("tourCrew")
            .whereField("tourId", isEqualTo: tourID)
            .count.getAggregation(source: .server)
        
        do {
            let managerSnapshot = try await managerTask
            if let doc = managerSnapshot.documents.first, let crewMember = try? doc.data(as: TourCrew.self) {
                await MainActor.run { self.tourManagerName = crewMember.name }
            }
        } catch {
            print("❗️ ERROR fetching tour manager: \(error.localizedDescription).")
            await MainActor.run { self.tourManagerName = "Not Assigned" }
        }
        
        do {
            let showCountResult = try await showCountTask
            await MainActor.run { self.showCount = showCountResult.count.intValue }
        } catch {
            print("Error fetching show count: \(error.localizedDescription)")
        }

        do {
            let crewCountResult = try await crewCountTask
            await MainActor.run { self.crewCount = crewCountResult.count.intValue }
        } catch {
            print("Error fetching crew count: \(error.localizedDescription)")
        }
    }
}
