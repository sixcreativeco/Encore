import SwiftUI
import FirebaseFirestore

struct ShowGridView: View {
    var tourID: String
    @State private var shows: [ShowModel] = []
    @State private var isShowingAddShow = false

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
                            Text(show.city).font(.headline)
                            Text(show.venue).font(.subheadline).foregroundColor(.secondary)
                            Text(show.date.formatted(date: .abbreviated, time: .omitted)).font(.body)
                        }
                        .frame(maxWidth: .infinity, minHeight: 160)
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }

                    Button(action: { isShowingAddShow = true }) {
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
        .sheet(isPresented: $isShowingAddShow) {
            AddShowView(tourID: tourID, onSave: loadShows)
        }
        .onAppear { loadShows() }
    }

    func loadShows() {
        let db = Firestore.firestore()
        db.collection("tours").document(tourID).collection("shows").order(by: "date").getDocuments { snapshot, error in
            if let docs = snapshot?.documents {
                self.shows = docs.compactMap { ShowModel(from: $0) }
            }
        }
    }
}
