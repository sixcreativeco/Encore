import SwiftUI
import FirebaseFirestore

struct HotelsSection: View {
    let userID: String
    let searchText: String
    let selectedFilter: String
    @Binding var sortField: String
    @Binding var sortAscending: Bool

    @State private var hotels: [HotelModel] = []
    @State private var isLoading: Bool = true

    var body: some View {
        VStack {
            if isLoading {
                Spacer()
                ProgressView().progressViewStyle(.circular)
                Spacer()
            } else {
                HotelTableView(hotels: filteredAndSorted(), sortField: $sortField, sortAscending: $sortAscending)
            }
        }
        .onAppear(perform: loadHotels)
    }

    private func loadHotels() {
        let db = Firestore.firestore()
        var collected: [HotelModel] = []

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
                        let name = data["hotelName"] as? String ?? ""
                        let address = data["hotelAddress"] as? String ?? ""
                        let city = data["city"] as? String ?? ""
                        let bookingReference = data["bookingReference"] as? String ?? ""
                        let contactName = data["contactName"] as? String ?? ""
                        let contactEmail = data["contactEmail"] as? String ?? ""
                        let contactPhone = data["contactPhone"] as? String ?? ""

                        if !name.isEmpty {
                            collected.append(
                                HotelModel(
                                    name: name,
                                    address: address,
                                    city: city,
                                    bookingReference: bookingReference,
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
                self.hotels = deduplicate(collected)
                self.isLoading = false
            }
        }
    }

    private func deduplicate(_ models: [HotelModel]) -> [HotelModel] {
        var dict: [String: HotelModel] = [:]
        for model in models where !model.name.isEmpty {
            let key = "\(model.name.lowercased())-\(model.city.lowercased())"
            dict[key] = model
        }
        return dict.values.sorted { $0.name < $1.name }
    }

    private func filteredAndSorted() -> [HotelModel] {
        let filtered = hotels.filter { hotel in
            let matchesFilter = selectedFilter == "All" || hotel.city == selectedFilter
            let matchesSearch = searchText.isEmpty || hotel.name.lowercased().contains(searchText.lowercased())
            return matchesFilter && matchesSearch
        }

        return filtered.sorted { lhs, rhs in
            let lhsValue = sortFieldValue(lhs)
            let rhsValue = sortFieldValue(rhs)
            return sortAscending ? lhsValue < rhsValue : lhsValue > rhsValue
        }
    }

    private func sortFieldValue(_ hotel: HotelModel) -> String {
        switch sortField {
        case "City": return hotel.city
        default: return hotel.name
        }
    }
}
