import SwiftUI
import FirebaseFirestore

struct ShowModel: Identifiable, Codable, Hashable {
    var id: String
    var city: String
    var country: String?
    var venue: String
    var address: String
    var date: Date

    func toDictionary() -> [String: Any] {
        return [
            "city": city,
            "country": country ?? "",
            "venue": venue,
            "address": address,
            "date": Timestamp(date: date)
        ]
    }

    static func fromDictionary(_ id: String, _ dict: [String: Any]) -> ShowModel {
        return ShowModel(
            id: id,
            city: dict["city"] as? String ?? "",
            country: dict["country"] as? String,
            venue: dict["venue"] as? String ?? "",
            address: dict["address"] as? String ?? "",
            date: (dict["date"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

struct ShowGridView: View {
    var tourID: String
    @State private var shows: [ShowModel] = []
    @State private var isShowingAddShowView = false

    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shows")
                .font(.title2.bold())
                .padding(.horizontal)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(shows) { show in
                        VStack(alignment: .leading, spacing: 6) {
                            if let country = show.country, !country.isEmpty {
                                Text(country)
                                    .font(.headline)
                            } else {
                                Text(show.city)
                                    .font(.headline)
                            }

                            Text(show.venue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(show.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 160)
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }

                    Button(action: {
                        isShowingAddShowView = true
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .medium))
                            Text("Add Show")
                                .font(.headline)
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
            AddShowView(tourID: tourID) { newShow in
                let model = ShowModel(
                    id: UUID().uuidString,
                    city: newShow["city"] as? String ?? "",
                    country: newShow["country"] as? String,
                    venue: newShow["venue"] as? String ?? "",
                    address: newShow["address"] as? String ?? "",
                    date: (newShow["date"] as? Timestamp)?.dateValue() ?? Date()
                )

                shows.append(model)
                OfflineSyncManager.shared.upsertShow(model, for: tourID)
            }
        }
        .onAppear {
            loadShows()
        }
    }

    func loadShows() {
        let db = Firestore.firestore()
        db.collection("tours").document(tourID).collection("stops").order(by: "date").getDocuments { snapshot, error in
            if let docs = snapshot?.documents {
                self.shows = docs.map { doc in
                    ShowModel.fromDictionary(doc.documentID, doc.data())
                }

                OfflineSyncManager.shared.cacheShows(for: tourID, shows: self.shows)
            } else {
                print("⚠️ Error fetching shows: \(error?.localizedDescription ?? "No internet")")
                self.shows = OfflineSyncManager.shared.getShows(for: tourID)
            }
        }
    }
}
