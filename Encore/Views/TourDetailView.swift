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
                    .padding(.horizontal, 24)
                
                TourSummaryCardsView(tourID: tour.id ?? "", ownerUserID: tour.ownerId)
                    .environmentObject(appState)
                    .padding(.horizontal, 24)
                
                HStack(alignment: .top, spacing: 24) {
                    
                    TourItineraryView(tour: tour)

                    ScrollView {
                        VStack(spacing: 24) {
                            TourCrewView(
                                tourID: tour.id ?? "",
                                ownerUserID: tour.ownerId
                            )
                            TourFlightsView(
                                tourID: tour.id ?? ""
                            )
                            // --- ADDITION IS HERE ---
                            TourHotelsView(
                                tourID: tour.id ?? ""
                            )
                            // ------------------------
                        }
                    }
                    .frame(height: 700) //  Give the right column a fixed height
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
