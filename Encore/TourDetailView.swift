import SwiftUI

struct TourDetailView: View {
    var tour: TourModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                
                TourHeaderView(tour: tour)
                
                TourSummaryCardsView(tourID: tour.id)
                    .environmentObject(appState)
                
                GeometryReader { geometry in
                    HStack(alignment: .top, spacing: 24) {
                        
                        ScrollView {
                            TourItineraryView(tourID: tour.id, userID: appState.userID ?? "")
                                .padding(.trailing, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(width: geometry.size.width * 0.6, height: 500)
                        
                        ScrollView {
                            VStack(spacing: 24) {
                                TourCrewView(tourID: tour.id)
                                TourFlightsView(tourID: tour.id)
                            }
                            .padding(.leading, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(width: geometry.size.width * 0.35, height: 500)
                    }
                }
                .frame(height: 500)
                
                if let userID = appState.userID {
                    ShowGridView(
                        tourID: tour.id,
                        userID: userID,
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
