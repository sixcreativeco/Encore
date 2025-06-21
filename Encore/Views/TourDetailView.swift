import SwiftUI
import FirebaseFirestore

struct TourDetailView: View {
    var tour: Tour
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                TourHeaderView(tour: tour)
                
                TourSummaryCardsView(tourID: tour.id ?? "", ownerUserID: tour.ownerId)
                    .environmentObject(appState)
                
                HStack(alignment: .firstTextBaseline, spacing: 24) {
                    
                    TourItineraryView(tour: tour)
                    .frame(height: 500)

                    ScrollView {
                        VStack(spacing: 24) {
                            TourCrewView(
                                tourID: tour.id ?? "",
                                ownerUserID: tour.ownerId
                            )
                            
                            // FIX: This call is now corrected.
                            // It only passes the tourID, matching the new TourFlightsView.
                            TourFlightsView(
                                tourID: tour.id ?? ""
                            )
                        }
                        .padding()
                    }
                    .frame(height: 500)
                }

                if let tourID = tour.id {
                    ShowGridView(
                        tourID: tourID,
                        ownerUserID: tour.ownerId,
                        artistName: tour.artist,
                        onShowSelected: { selectedShow in
                            appState.selectedShow = selectedShow
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
