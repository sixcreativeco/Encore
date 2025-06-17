import SwiftUI
import FirebaseFirestore

struct ContactsSection: View {
    let userID: String
    let searchText: String
    let selectedFilter: String
    @Binding var sortField: String
    @Binding var sortAscending: Bool

    @State private var contacts: [ContactModel] = []
    @State private var isLoading: Bool = true

    var body: some View {
        Group {
            if isLoading {
                VStack { Spacer(); ProgressView().progressViewStyle(.circular); Spacer() }
            } else {
                ContactsTableView(contacts: filteredAndSorted, sortField: $sortField, sortAscending: $sortAscending)
            }
        }
        .onAppear(perform: loadContacts)
    }

    private var filteredAndSorted: [ContactModel] {
        contacts
            .filter { contact in
                (selectedFilter == "All" || contact.role == selectedFilter) &&
                (searchText.isEmpty || contact.matches(searchText))
            }
    }

    private func loadContacts() {
        let db = Firestore.firestore()
        var collected: [ContactModel] = []

        db.collection("users").document(userID).collection("tours").getDocuments { snapshot, _ in
            let tourDocs = snapshot?.documents ?? []
            let group = DispatchGroup()

            for tourDoc in tourDocs {
                let tourID = tourDoc.documentID
                let artistName = tourDoc.data()["artistName"] as? String ?? ""

                if !artistName.isEmpty {
                    collected.append(ContactModel(name: artistName, role: "Artist"))
                }

                group.enter()
                db.collection("users").document(userID).collection("tours").document(tourID).collection("crew").getDocuments { crewSnap, _ in
                    for doc in crewSnap?.documents ?? [] {
                        let name = doc.data()["name"] as? String ?? ""
                        let role = doc.data()["role"] as? String ?? ""
                        let email = doc.data()["email"] as? String
                        collected.append(ContactModel(name: name, role: role, email: email))
                    }
                    group.leave()
                }

                group.enter()
                db.collection("users").document(userID).collection("tours").document(tourID).collection("shows").getDocuments { showSnap, _ in
                    let showDocs = showSnap?.documents ?? []
                    let showGroup = DispatchGroup()

                    for showDoc in showDocs {
                        let showID = showDoc.documentID

                        showGroup.enter()
                        db.collection("users").document(userID).collection("tours").document(tourID).collection("shows").document(showID).collection("supportActs").getDocuments { supportSnap, _ in
                            for supDoc in supportSnap?.documents ?? [] {
                                let name = supDoc.data()["name"] as? String ?? ""
                                collected.append(ContactModel(name: name, role: "Support Act"))
                            }
                            showGroup.leave()
                        }

                        showGroup.enter()
                        db.collection("users").document(userID).collection("tours").document(tourID).collection("shows").document(showID).collection("guestlist").getDocuments { guestSnap, _ in
                            for guestDoc in guestSnap?.documents ?? [] {
                                let name = guestDoc.data()["name"] as? String ?? ""
                                let note = guestDoc.data()["note"] as? String
                                collected.append(ContactModel(name: name, role: "Guest", notes: note))
                            }
                            showGroup.leave()
                        }
                    }

                    showGroup.notify(queue: .main) { group.leave() }
                }
            }

            group.notify(queue: .main) {
                self.contacts = collected
                self.isLoading = false
            }
        }
    }
}
