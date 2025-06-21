import SwiftUI

struct MobileMainView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTabTag = 0 // Used to programmatically switch tabs

    var body: some View {
        TabView(selection: $selectedTabTag) {
            // MARK: - Tours Tab
            NavigationView {
                TourListView(onTourSelected: { tour in
                    appState.selectedTour = tour
                    self.selectedTabTag = 1 // Switch to Itinerary tab on selection
                })
                .navigationTitle("Tours")
            }
            .tabItem {
                Label("Tours", systemImage: "music.mic")
            }
            .tag(0)

            // MARK: - Itinerary Tab
            NavigationView {
                // This view shows the itinerary for the tour selected in the first tab
                if let tour = appState.selectedTour {
                    TourItineraryView(tour: tour)
                        .navigationTitle(tour.tourName)
                } else {
                    VStack {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                            .padding(.bottom)
                        Text("No Tour Selected")
                            .font(.headline)
                        Text("Select a tour from the Tours tab to see its itinerary.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .navigationTitle("Itinerary")
                }
            }
            .tabItem {
                Label("Itinerary", systemImage: "calendar")
            }
            .tag(1)

            // MARK: - My Account Tab
            NavigationView {
                MyAccountView()
                    .navigationTitle("My Account")
            }
            .tabItem {
                Label("My Account", systemImage: "person.crop.circle")
            }
            .tag(2)
        }
    }
}
