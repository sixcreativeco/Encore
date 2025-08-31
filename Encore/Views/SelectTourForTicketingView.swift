import SwiftUI
import Kingfisher
import FirebaseFirestore
import FirebaseAuth

struct SelectTourForTicketingView: View {
    @StateObject private var viewModel = SelectTourViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    // This completion handler will pass the selected tour back to the parent view.
    var onTourSelected: (Tour) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            
            if viewModel.isLoading {
                ProgressView("Loading Tours...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.toursWithShowCounts.isEmpty {
                Text("You haven't created any tours yet.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.toursWithShowCounts, id: \.tour.id) { tourWithCount in
                            tourRow(tour: tourWithCount.tour, showCount: tourWithCount.showCount)
                        }
                    }
                }
            }
        }
        .padding(30)
        .frame(minWidth: 600, minHeight: 700)
        .task {
            if let userID = appState.userID {
                await viewModel.fetchTours(for: userID)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Select a Tour")
                .font(.largeTitle.bold())
            Spacer()
            Button(action: { dismiss() }) {
                 Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
    }

    private func tourRow(tour: Tour, showCount: Int) -> some View {
        HStack(spacing: 20) {
            KFImage(URL(string: tour.posterURL ?? ""))
                .placeholder { Color.gray.opacity(0.1) }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 120)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 6) {
                Text(tour.artist)
                    .font(.headline)
                Text(tour.tourName)
                    .font(.title2.bold())
                Text("\(showCount) shows")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Configure Tickets") {
                // Call the completion handler with the selected tour and dismiss the sheet
                onTourSelected(tour)
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle(color: .blue))
        }
        .padding()
        .background(Material.regular)
        .cornerRadius(12)
    }
}
