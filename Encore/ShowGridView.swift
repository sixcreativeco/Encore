import SwiftUI
import FirebaseFirestore

struct ShowGridView: View {
    var tourID: String
    var userID: String
    var artistName: String

    @State private var shows: [ShowModel] = []
    @State private var isShowingAddShowView = false

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
                    VStack {
                        Text(show.city).font(.headline)
                        Text(show.venue).font(.subheadline)
                        Text(show.date.formatted(date: .abbreviated, time: .omitted)).font(.caption)
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(12)
                }

                Button(action: { isShowingAddShowView = true }) {
                    VStack {
                        Image(systemName: "plus.circle.fill").font(.system(size: 40))
                        Text("Add Show")
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.10))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $isShowingAddShowView) {
            AddShowView(tourID: tourID, userID: userID, artistName: artistName) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    loadShows()
                }
            }
        }
        .onAppear { loadShows() }
    }

    private func loadShows() {
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("tours").document(tourID).collection("shows")
            .order(by: "date")
            .getDocuments { snapshot, _ in
                self.shows = snapshot?.documents.compactMap { ShowModel(from: $0) } ?? []
            }
    }
}
