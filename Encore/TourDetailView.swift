import SwiftUI
import FirebaseFirestore

struct TourDetailView: View {
    var tour: TourModel
    @State private var shows: [LocalShow] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let url = URL(string: tour.posterURL ?? "") {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: 200)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(12)
                        case .failure:
                            Color.gray
                                .frame(height: 200)
                                .cornerRadius(12)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(tour.name)
                        .font(.largeTitle.bold())
                    Text("By \(tour.artist)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("\(tour.startDate.formatted(date: .abbreviated, time: .omitted)) - \(tour.endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                Text("Shows")
                    .font(.title2.bold())

                if shows.isEmpty {
                    Text("No shows yet.")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                } else {
                    ForEach(shows) { show in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(show.venue)
                                .font(.headline)
                            Text("\(show.city), \(show.country ?? "")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(show.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            loadShows()
        }
        .navigationTitle("Tour Details")
    }

    func loadShows() {
        let db = Firestore.firestore()
        db.collection("tours").document(tour.id).collection("stops").order(by: "date", descending: false).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("❌ Failed to fetch shows: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            self.shows = documents.compactMap { doc in
                let data = doc.data()
                guard
                    let city = data["city"] as? String,
                    let venue = data["venue"] as? String,
                    let address = data["address"] as? String,
                    let date = (data["date"] as? Timestamp)?.dateValue()
                else {
                    return nil
                }

                return LocalShow(
                    city: city,
                    country: data["country"] as? String,
                    venue: venue,
                    address: address,
                    date: date
                )
            }
        }
    }
}

struct LocalShow: Identifiable {
    let id = UUID()
    let city: String
    let country: String?
    let venue: String
    let address: String
    let date: Date
}
