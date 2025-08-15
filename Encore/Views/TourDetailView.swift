import SwiftUI
import FirebaseFirestore

struct TourDetailView: View {
    let tour: Tour
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                TourHeaderView(tour: tour)
                    .padding(.horizontal, 24)
                        
                TourSummaryCardsView(tourID: tour.id ?? "", ownerUserID: tour.ownerId)
                    .environmentObject(appState)
                    .padding(.horizontal, 24)
                            
                HStack(alignment: .top, spacing: 24) {
                    // Create the itinerary view with explicit initialization
                    TourItineraryView(tour: tour)
                        .environmentObject(appState)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            TourCrewView(
                                tourID: tour.id ?? "",
                                ownerUserID: tour.ownerId
                            )

                            // --- THIS IS THE FIX ---
                            // The TourFlightsView now receives the entire `tour` object.
                            // This gives it access to the `ownerId` needed for saving new flights securely.
                            TourFlightsView(tour: tour)
                            // --- END OF FIX ---

                            TourHotelsView(
                                tourID: tour.id ?? ""
                            )
                        }
                    }
                    .frame(height: 700)
                }
                .padding(.horizontal, 24)
                
                if let tourID = tour.id {
                    ShowGridView(
                        tourID: tourID,
                        ownerUserID: tour.ownerId,
                        artistName: tour.artist,
                        onShowSelected: { selectedShow in
                            appState.selectedShow = selectedShow
                        }
                    )
                    .padding(.horizontal, 24)
                }
            }
            .padding(.vertical)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
