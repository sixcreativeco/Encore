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
                
                GeometryReader { geometry in
                    HStack(alignment: .top, spacing: 24) {
                        ScrollView {
                            TourItineraryView(
                                tourID: tour.id,
                                userID: appState.userID ?? "",
                                ownerUserID: tour.ownerUserID
                            )
                            .padding(.trailing, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(width: geometry.size.width * 0.5, height: 500)

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
                            .padding(.leading, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(width: geometry.size.width * 0.45, height: 500)
                    }
                }
                .frame(height: 500)

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
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea()
    }
}
