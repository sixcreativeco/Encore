import SwiftUI
import FirebaseFirestore

struct TourDetailView: View {
    var tour: TourModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                TourHeaderView(tour: tour)
                
                TourSummaryCardsView(tourID: tour.id, ownerUserID: tour.ownerUserID)
                    .environmentObject(appState)
                
                // FIX: Changed alignment from .top to .firstTextBaseline
                HStack(alignment: .firstTextBaseline, spacing: 24) {
                    
                    // --- LEFT ITINERARY COLUMN ---
                    TourItineraryView(
                        tourID: tour.id,
                        userID: appState.userID ?? "",
                        ownerUserID: tour.ownerUserID
                    )
                    .frame(height: 500)

                    // --- RIGHT CREW/FLIGHTS COLUMN ---
                    ScrollView {
                        VStack(spacing: 24) {
                            TourCrewView(
                                tourID: tour.id,
                                ownerUserID: tour.ownerUserID
                            )
                            TourFlightsView(
                                tourID: tour.id,
                                userID: appState.userID ?? "",
                                ownerUserID: tour.ownerUserID
                            )
                        }
                        .padding()
                    }
                    .frame(height: 500)
                }

                if let userID = appState.userID {
                    ShowGridView(
                        tourID: tour.id,
                        userID: userID,
                        ownerUserID: tour.ownerUserID,
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
