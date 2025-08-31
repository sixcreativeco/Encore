import SwiftUI
import FirebaseFirestore

struct ShowGridView: View {
    var tourID: String
    var ownerUserID: String
    var artistName: String
    
    var onShowSelected: (Show) -> Void

    // Bindings to enable selection mode
    @Binding var isSelectionModeActive: Bool
    @Binding var selectedShowIDs: Set<String>

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

            LazyVGrid(columns: columns, spacing: 20) {
                 ForEach(shows) { show in
                    ShowCardView(
                        show: show,
                        onSelect: { onShowSelected(show) },
                        onEdit: { self.showToEdit = show },
                        isSelectionModeActive: $isSelectionModeActive,
                        selectedShowIDs: $selectedShowIDs
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
    
    // Private View for the Show Card to manage its own hover state and selection state
    private struct ShowCardView: View {
        let show: Show
        var onSelect: () -> Void
        var onEdit: () -> Void

        @Binding var isSelectionModeActive: Bool
        @Binding var selectedShowIDs: Set<String>

        #if os(macOS)
        @State private var isHovering = false
        #endif

        private var isSelected: Bool {
            guard let showId = show.id else { return false }
            return selectedShowIDs.contains(showId)
        }

        var body: some View {
             ZStack(alignment: .topTrailing) {
                Button(action: {
                    if isSelectionModeActive {
                        guard let showId = show.id else { return }
                        if isSelected {
                            selectedShowIDs.remove(showId)
                        } else {
                            selectedShowIDs.insert(showId)
                        }
                    } else {
                        onSelect()
                    }
                }) {
                    VStack {
                        Text(show.city).font(.headline)
                        Text(show.venueName).font(.subheadline)
                         Text(formattedShowDate(for: show)).font(.caption)
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                     .background(Color.black.opacity(0.15))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
                }
                .buttonStyle(.plain)
                
                if isSelectionModeActive {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .padding(8)
                        .transition(.opacity.combined(with: .scale))
                } else {
                    // Edit Button Overlay
                    #if os(macOS)
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                     .buttonStyle(.plain)
                    .padding(6)
                    .opacity(isHovering ? 1 : 0)
                    #else
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
            }
            #if os(macOS)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                     self.isHovering = hovering
                }
            }
            #endif
            .animation(.easeInOut(duration: 0.2), value: isSelectionModeActive)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
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
