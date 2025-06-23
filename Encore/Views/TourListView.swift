import SwiftUI
import FirebaseFirestore
import Kingfisher

struct TourListView: View {
    @EnvironmentObject var appState: AppState
    
    var onTourSelected: ((Tour) -> Void)? = nil

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
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {

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
                                    Button(action: {
                                        onTourSelected?(tour)
                                    }) {
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
                                    Button(action: {
                                        onTourSelected?(tour)
                                    }) {
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
        .background(.clear)
        .onAppear {
            appState.loadTours()
            preloadPosterImages(for: appState.tours)
        }
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
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            KFImage(URL(string: tour.posterURL ?? ""))
                .placeholder { Color.gray.opacity(0.1) }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 130, height: 195)
                .cornerRadius(8)

            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(tour.artist.uppercased())
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .tracking(1.5)
                    
                    Text(tour.tourName)
                        .font(.system(size: 32, weight: .bold))

                    Label("\(compactDateFormatter.string(from: tour.startDate.dateValue())) - \(compactDateFormatter.string(from: tour.endDate.dateValue()))", systemImage: "calendar")
                        .foregroundColor(.secondary)

                    if let tourManagerName = tourManagerName {
                        Label(tourManagerName, systemImage: "person.fill")
                            .foregroundColor(.secondary)
                    }
                    
                    Label("\(showCount) Shows", systemImage: "music.mic")
                        .foregroundColor(.secondary)

                    Label("\(crewCount) Crew Members", systemImage: "person.3.fill")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 5)

                Spacer()

                HStack {
                    Spacer()
                    Button(action: {
                        onTourSelected?(tour)
                    }) {
                        Text("Go To Tour")
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 48)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .frame(height: 220)
        .background(Color.black.opacity(0.25))
        .cornerRadius(16)
        .onAppear {
            Task {
                await fetchExtraTourInfo()
            }
        }
    }

    private func fetchExtraTourInfo() async {
        guard let tourID = tour.id else { return }
        let db = Firestore.firestore()
        
        // Fetch Tour Manager
        async let managerTask = db.collection("tourCrew")
            .whereField("tourId", isEqualTo: tourID)
            .whereField("roles", arrayContains: "Tour Manager")
            .limit(to: 1).getDocuments()

        // Fetch Show Count
        async let showCountTask = db.collection("shows")
            .whereField("tourId", isEqualTo: tourID)
            .count.getAggregation(source: .server)

        // Fetch Crew Count
        async let crewCountTask = db.collection("tourCrew")
            .whereField("tourId", isEqualTo: tourID)
            .count.getAggregation(source: .server)
        
        do {
            let managerSnapshot = try await managerTask
            if let doc = managerSnapshot.documents.first, let crewMember = try? doc.data(as: TourCrew.self) {
                await MainActor.run { self.tourManagerName = crewMember.name }
            }
            print("Successfully fetched tour manager.")
        } catch {
            print("❗️ ERROR fetching tour manager: \(error.localizedDescription). This may require a composite index in Firestore.")
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
