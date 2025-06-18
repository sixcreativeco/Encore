import SwiftUI

struct ExportView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var shows: [ShowModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    private var mediumDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Export Center")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let tour = appState.selectedTour {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Export Documents for \(tour.name)")
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
        .onChange(of: appState.selectedTour) { newTour in
            fetchShows(for: newTour)
        }
    }
    
    private func showExportRow(show: ShowModel, tour: TourModel) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(show.city)
                    .fontWeight(.bold)
                Text("\(show.venue) - \(mediumDateFormatter.string(from: show.date))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            ExportShowTimingButton(show: show, tour: tour)
        }
        .padding(.vertical, 8)
    }

    private func fetchShows(for tour: TourModel?) {
        guard let tour = tour else {
            self.shows = []
            return
        }
        
        self.isLoading = true
        self.shows = []
        self.errorMessage = nil
        
        Task {
            do {
                let fetchedShows = try await FirebaseTourService.fetchShows(forTour: tour.id, ownerID: tour.ownerUserID)
                
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
