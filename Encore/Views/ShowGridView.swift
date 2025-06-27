import SwiftUI
import FirebaseFirestore

struct ShowGridView: View {
    var tourID: String
    var ownerUserID: String
    var artistName: String
    
    var onShowSelected: (Show) -> Void

    @State private var shows: [Show] = []
    @State private var isShowingAddShowView = false
    @State private var showToEdit: Show?
    
    @State private var listener: ListenerRegistration?
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shows").font(.headline)

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(shows) { show in
                    ShowCardView(
                        show: show,
                        onSelect: { onShowSelected(show) },
                        onEdit: { self.showToEdit = show }
                    )
                }

                Button(action: { isShowingAddShowView = true }) {
                    VStack {
                        Image(systemName: "plus.circle.fill").font(.system(size: 40))
                        Text("Add Show")
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.15))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $isShowingAddShowView) {
            AddShowView(tourID: tourID, userID: ownerUserID, artistName: artistName) { }
        }
        .sheet(item: $showToEdit) { show in
            if let index = shows.firstIndex(where: { $0.id == show.id }) {
                ShowEditView(tour: appState.selectedTour!, show: $shows[index])
            }
        }
        .onAppear { listenForShows() }
        .onDisappear { listener?.remove() }
    }
    
    @EnvironmentObject var appState: AppState
    
    private func listenForShows() {
        listener?.remove()
        
        let db = Firestore.firestore()
        
        listener = db.collection("shows")
            .whereField("tourId", isEqualTo: tourID)
            .order(by: "date")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error listening for show updates: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                self.shows = documents.compactMap { try? $0.data(as: Show.self) }
            }
    }
    
    // Private View for the Show Card to manage its own hover state
    private struct ShowCardView: View {
        let show: Show
        var onSelect: () -> Void
        var onEdit: () -> Void

        #if os(macOS)
        @State private var isHovering = false
        #endif

        var body: some View {
            ZStack(alignment: .topTrailing) {
                Button(action: onSelect) {
                    VStack {
                        Text(show.city).font(.headline)
                        Text(show.venueName).font(.subheadline)
                        Text(formattedShowDate(for: show)).font(.caption)
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.15))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                // Edit Button Overlay
                #if os(macOS)
                Button(action: onEdit) {
                    Image(systemName: "pencil") // Non-fill icon
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(6)
                .opacity(isHovering ? 1 : 0) // Fades in/out
                #else
                // For iOS, show a clear, tappable icon all the time
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 20))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.black.opacity(0.4))
                }
                .buttonStyle(.plain)
                .padding(8)
                #endif
            }
            #if os(macOS)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isHovering = hovering
                }
            }
            #endif
        }
        
        private func formattedShowDate(for show: Show) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM yy"
            if let timezoneIdentifier = show.timezone {
                formatter.timeZone = TimeZone(identifier: timezoneIdentifier)
            }
            return formatter.string(from: show.date.dateValue())
        }
    }
}
