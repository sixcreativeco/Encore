import SwiftUI

struct ExportView: View {
    @EnvironmentObject var appState: AppState
    
    // FIX: State variable now uses the new 'Show' model.
    @State private var shows: [Show] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    private var mediumDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    var body: some View {
        // NOTE: The UI layout of this view is unchanged.
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Export Center")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                // FIX: This now correctly checks for the new 'Tour' model from AppState.
                if let tour = appState.selectedTour {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Export Documents for \(tour.tourName)")
                            .font(.title2.bold())
                        Divider()
                        
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView("Loading Shows...")
                                Spacer()
                            }
                            .padding(.top, 40)
                        } else if let error = errorMessage {
                            VStack {
                                Text("Error Loading Data")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                        } else if shows.isEmpty {
                            Text("This tour has no shows to export.")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 40)
                        } else {
                            Text("Show Day Sheets").font(.headline)
                            // The ForEach now iterates over the new [Show] array.
                            ForEach(shows) { show in
                                showExportRow(show: show, tour: tour)
                                Divider()
                            }
                        }
                    }
                } else {
                    VStack(alignment: .center, spacing: 16) {
                        Spacer(minLength: 50)
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No Tour Selected")
                            .font(.title2.bold())
                        Text("Select a tour from the 'Tours' tab to see export options.")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(30)
        }
        .onAppear {
            fetchShows(for: appState.selectedTour)
        }
        .onChange(of: appState.selectedTour) { _, newTour in
            fetchShows(for: newTour)
        }
    }
    
    // FIX: This function now accepts the new 'Show' and 'Tour' models.
    private func showExportRow(show: Show, tour: Tour) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(show.city)
                    .fontWeight(.bold)
                Text("\(show.venueName) - \(mediumDateFormatter.string(from: show.date.dateValue()))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            // This now correctly passes the new models to the button view we already fixed.
            ExportShowTimingButton(show: show, tour: tour)
        }
        .padding(.vertical, 8)
    }

    // FIX: This function now accepts the new 'Tour' model and calls the new service method.
    private func fetchShows(for tour: Tour?) {
        guard let tour = tour, let tourID = tour.id else {
            self.shows = []
            return
        }
        
        self.isLoading = true
        self.shows = []
        self.errorMessage = nil
        
        Task {
            do {
                let fetchedShows = try await FirebaseTourService.fetchShows(forTour: tourID)
                
                await MainActor.run {
                    self.shows = fetchedShows
                    self.isLoading = false
                }
            } catch {
                let errorDescription = error.localizedDescription
                print("❌ Failed to fetch shows: \(errorDescription)")
                await MainActor.run {
                    self.errorMessage = errorDescription
                    self.isLoading = false
                }
            }
        }
    }
}
