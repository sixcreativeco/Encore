import SwiftUI
import FirebaseFirestore

struct ShowGridView: View {
    var tourID: String
    var ownerUserID: String
    var artistName: String
    
    var onShowSelected: (Show) -> Void

    @State private var shows: [Show] = []
    @State private var isShowingAddShowView = false
    
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
                    Button(action: { onShowSelected(show) }) {
                        VStack {
                            Text(show.city).font(.headline)
                            Text(show.venueName).font(.subheadline)
                            Text(show.date.dateValue().formatted(date: .abbreviated, time: .omitted)).font(.caption)
                        }
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.15))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
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
        .onAppear { listenForShows() }
        .onDisappear { listener?.remove() }
    }

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
}
