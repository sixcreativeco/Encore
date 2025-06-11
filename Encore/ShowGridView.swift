import SwiftUI
import FirebaseFirestore

struct ShowGridView: View {
    var tourID: String
    var userID: String
    @State private var shows: [ShowModel] = []
    @State private var isShowingAddShowView = false

    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shows").font(.title2.bold()).padding(.horizontal)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(shows) { show in
                        VStack(alignment: .leading, spacing: 6) {
                            if let country = show.country, !country.isEmpty {
                                Text(country).font(.headline)
                            } else {
                                Text(show.city).font(.headline)
                            }
                            Text(show.venue).font(.subheadline).foregroundColor(.secondary)
                            Text(show.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.body).foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 160)
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }

                    Button(action: { isShowingAddShowView = true }) {
                        VStack(spacing: 12) {
                            Image(systemName: "plus").font(.system(size: 24, weight: .medium))
                            Text("Add Show").font(.headline)
                        }
                        .frame(maxWidth: .infinity, minHeight: 160)
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $isShowingAddShowView) {
            AddShowView(tourID: tourID, userID: userID) {
                loadShows()
            }
        }
        .onAppear { loadShows() }
    }

    private func loadShows() {
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("tours").document(tourID).collection("shows")
            .order(by: "date").getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    self.shows = docs.compactMap { ShowModel(from: $0) }
                }
            }
    }
}
