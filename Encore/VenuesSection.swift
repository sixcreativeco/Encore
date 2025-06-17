import SwiftUI
import FirebaseFirestore

struct VenuesSection: View {
    let userID: String
    let searchText: String
    let selectedFilter: String
    @Binding var sortField: String
    @Binding var sortAscending: Bool

    @State private var venues: [VenueModel] = []
    @State private var isLoading: Bool = true

    var body: some View {
        VStack {
            if isLoading {
                Spacer()
                ProgressView().progressViewStyle(.circular)
                Spacer()
            } else {
                ScrollView {
                    VenueTableView(venues: filteredAndSorted(), sortField: $sortField, sortAscending: $sortAscending)
                }
            }
        }
        .onAppear(perform: loadVenues)
    }

    private func loadVenues() {
        let db = Firestore.firestore()
        var collected: [VenueModel] = []

        db.collection("users").document(userID).collection("tours").getDocuments { snapshot, _ in
            let tourDocs = snapshot?.documents ?? []
            let group = DispatchGroup()

            for tourDoc in tourDocs {
                let tourID = tourDoc.documentID

                group.enter()
                db.collection("users").document(userID).collection("tours").document(tourID).collection("shows").getDocuments { showSnap, _ in
                    let showDocs = showSnap?.documents ?? []

                    for showDoc in showDocs {
                        let data = showDoc.data()
                        let name = data["venue"] as? String ?? ""
                        let address = data["address"] as? String ?? ""
                        let city = data["city"] as? String ?? ""
                        let contactName = data["contactName"] as? String ?? ""
                        let contactEmail = data["contactEmail"] as? String ?? ""
                        let contactPhone = data["contactPhone"] as? String ?? ""

                        if !name.isEmpty {
                            collected.append(
                                VenueModel(
                                    name: name,
                                    address: address,
                                    city: city,
                                    contactName: contactName,
                                    contactEmail: contactEmail,
                                    contactPhone: contactPhone
                                )
                            )
                        }
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.venues = deduplicate(collected)
                self.isLoading = false
            }
        }
    }

    private func deduplicate(_ models: [VenueModel]) -> [VenueModel] {
        var dict: [String: VenueModel] = [:]
        for model in models where !model.name.isEmpty {
            let key = "\(model.name.lowercased())-\(model.city.lowercased())"
            dict[key] = model
        }
        return dict.values.sorted { $0.name < $1.name }
    }

    private func filteredAndSorted() -> [VenueModel] {
        let filtered = venues.filter { venue in
            let matchesFilter = selectedFilter == "All" || venue.city == selectedFilter
            let matchesSearch = searchText.isEmpty || venue.name.lowercased().contains(searchText.lowercased())
            return matchesFilter && matchesSearch
        }

        return filtered.sorted { lhs, rhs in
            let lhsValue = sortFieldValue(lhs)
            let rhsValue = sortFieldValue(rhs)
            return sortAscending ? lhsValue < rhsValue : lhsValue > rhsValue
        }
    }

    private func sortFieldValue(_ venue: VenueModel) -> String {
        switch sortField {
        case "City": return venue.city
        default: return venue.name
        }
    }
}
