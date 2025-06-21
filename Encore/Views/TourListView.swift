import SwiftUI
import FirebaseFirestore
import Kingfisher

struct TourListView: View {
    @EnvironmentObject var appState: AppState
    
    // FIX: The closure now uses the new 'Tour' model.
    var onTourSelected: ((Tour) -> Void)? = nil

    // FIX: These are now simple computed properties that filter the appState.tours array.
    // This removes the need for local state and redundant data fetching.
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
        // NOTE: The UI structure below is identical to your original file.
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {

                if !upcomingTours.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming")
                            .font(.title2.bold())
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // The ForEach now iterates over the new computed property.
                                ForEach(upcomingTours) { tour in
                                    Button(action: {
                                        onTourSelected?(tour)
                                    }) {
                                        // TourCard was already fixed to accept the new 'Tour' model.
                                        TourCard(tour: tour)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                if !currentTours.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Tours")
                            .font(.title2.bold())
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(currentTours) { tour in
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
        .onAppear {
            // Instead of loading locally, we just tell the central AppState to load.
            // AppState will handle duplicates and updates for us.
            appState.loadTours()
            
            // The preloading logic is still a good idea.
            preloadPosterImages(for: appState.tours)
        }
    }

    // FIX: This function is now much simpler.
    private func preloadPosterImages(for tours: [Tour]) {
        let urls = tours.compactMap { URL(string: $0.posterURL ?? "") }
        ImagePrefetcher(urls: urls).start()
    }
}
