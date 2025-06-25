import SwiftUI

struct MobileMainView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTabTag = 0
    @State private var isShowingNotifications = false

    var body: some View {
        TabView(selection: $selectedTabTag) {
            // MARK: - Dashboard Tab
            NavigationView {
                DashboardView()
                    .navigationTitle("Dashboard")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            NavigationLink(destination: MyAccountView()) {
                                Image(systemName: "person.crop.circle")
                                    .font(.title2)
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { isShowingNotifications = true }) {
                                Image(systemName: "bell")
                                    .font(.title2)
                                    .overlay(alignment: .topTrailing) {
                                        if !appState.notifications.isEmpty {
                                            Text("\(appState.notifications.count)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(5)
                                                .background(Color.red)
                                                .clipShape(Circle())
                                                .offset(x: 8, y: -8)
                                        }
                                    }
                            }
                        }
                    }
            }
            .tabItem {
                Label("Dashboard", systemImage: "rectangle.grid.2x2.fill")
            }
            .tag(0)
            .sheet(isPresented: $isShowingNotifications) {
                NotificationsView(isPresented: $isShowingNotifications)
            }

            // MARK: - Tours Tab
            NavigationView {
                TourListView(onTourSelected: { tour in
                    appState.selectedTour = tour
                    self.selectedTabTag = 2 // Switch to Itinerary tab on selection
                })
                .navigationTitle("Tours")
            }
            .tabItem {
                Label("Tours", systemImage: "music.mic")
            }
            .tag(1)

            // MARK: - Itinerary Tab
            NavigationView {
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
            .tag(2)
        }
    }
}
