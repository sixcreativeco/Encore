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
                
                // Columns wrapped inside a GeometryReader to stabilize widths
                GeometryReader { geometry in
                    HStack(alignment: .top, spacing: 24) {
                        
                        ScrollView {
                            TourItineraryView(tourID: tour.id)
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
                .frame(height: 500) // total height of columns section
                
                // ShowGrid always appears after main section
                if let userID = appState.userID {
                    ShowGridView(tourID: tour.id, userID: userID, artistName: tour.artist)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea()
    }
}
