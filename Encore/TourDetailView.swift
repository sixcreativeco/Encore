import SwiftUI
import FirebaseFirestore

struct TourDetailView: View {
    var tour: TourModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var showingDeleteConfirmation = false

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
                        .frame(width: geometry.size.width * 0.5, height: 500)

                        ScrollView {
                            VStack(spacing: 24) {
                                TourCrewView(tourID: tour.id)
                                TourFlightsView(tourID: tour.id, userID: appState.userID ?? "") // ✅ Pass userID here
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
                        artistName: tour.artist,
                        onShowSelected: { selectedShow in
                            appState.selectedShow = selectedShow
                        }
                    )
                    .frame(maxWidth: .infinity)
                }

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Text("Delete Tour")
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
                .confirmationDialog("Are you sure you want to delete this tour?\n\nThis can't be undone.", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                    Button("Delete Tour", role: .destructive) {
                        deleteTour()
                    }
                    Button("Cancel", role: .cancel) { }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea()
    }

    private func deleteTour() {
        guard let userID = appState.userID else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("tours").document(tour.id).delete { error in
            if let error = error {
                print("❌ Error deleting tour: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    appState.removeTour(tourID: tour.id)
                    appState.selectedTour = nil
                    dismiss()
                }
            }
        }
    }
}
