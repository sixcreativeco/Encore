import SwiftUI
import FirebaseFirestore

struct TourDetailView: View {
    let tour: Tour
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    // State to control the presentation of the CrewEditView sheet.
    @State private var isShowingCrewEditView = false
    
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
                        .environmentObject(appState)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // --- THIS IS THE FIX ---
                            // The TourCrewView is now a simple, clickable summary card.
                            // The SectionHeader provides the title and "add" button functionality.
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Crew") {
                                    isShowingCrewEditView = true
                                }
                                Button(action: { isShowingCrewEditView = true }) {
                                    TourCrewView(
                                        tourID: tour.id ?? "",
                                        ownerUserID: tour.ownerId
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            // --- END OF FIX ---
                            
                            TourFlightsView(tour: tour)

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
        .sheet(isPresented: $isShowingCrewEditView) {
            CrewEditView(tour: tour)
        }
    }
}
