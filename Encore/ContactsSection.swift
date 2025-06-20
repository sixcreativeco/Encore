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
    @State private var contactToEdit: ContactModel?

    var body: some View {
        Group {
            if isLoading {
                VStack { Spacer(); ProgressView().progressViewStyle(.circular); Spacer() }
            } else {
                ContactsTableView(
                    contacts: filteredAndSorted,
                    sortField: $sortField,
                    sortAscending: $sortAscending,
                    onContactSelected: { contact in
                        self.contactToEdit = contact
                    }
                )
            }
        }
        .onAppear(perform: loadContacts)
        .sheet(item: $contactToEdit) { contact in
            ContactEditView(contact: contact)
        }
    }

    private var filteredAndSorted: [ContactModel] {
        contacts
            .filter { contact in
                (selectedFilter == "All" || contact.roles.contains(selectedFilter)) &&
                (searchText.isEmpty || contact.matches(searchText))
            }
    }

    private func loadContacts() {
        let db = Firestore.firestore()
        var collected: [ContactModel] = []
        let group = DispatchGroup()

        // 1. Load from the master 'contacts' collection
        group.enter()
        db.collection("users").document(userID).collection("contacts").getDocuments { snapshot, _ in
            if let docs = snapshot?.documents {
                let masterContacts = docs.compactMap { ContactModel(from: $0) }
                collected.append(contentsOf: masterContacts)
            }
            group.leave()
        }

        // 2. Load from various other locations (tours, crew, shows)
        group.enter()
        db.collection("users").document(userID).collection("tours").getDocuments { snapshot, _ in
            let tourDocs = snapshot?.documents ?? []
            let tourGroup = DispatchGroup()

            if tourDocs.isEmpty {
                tourGroup.leave()
            } else {
                for tourDoc in tourDocs {
                    let tourID = tourDoc.documentID
                    let artistName = tourDoc.data()["artist"] as? String ?? ""

                    if !artistName.isEmpty {
                        collected.append(ContactModel(name: artistName, roles: ["Artist"]))
                    }

                    tourGroup.enter()
                    db.collection("users").document(userID).collection("tours").document(tourID).collection("crew").getDocuments { crewSnap, _ in
                        for doc in crewSnap?.documents ?? [] {
                            let name = doc.data()["name"] as? String ?? ""
                            let roles = doc.data()["roles"] as? [String] ?? []
                            let email = doc.data()["email"] as? String
                            collected.append(ContactModel(name: name, roles: roles, email: email))
                        }
                        tourGroup.leave()
                    }

                    tourGroup.enter()
                    db.collection("users").document(userID).collection("tours").document(tourID).collection("shows").getDocuments { showSnap, _ in
                        let showDocs = showSnap?.documents ?? []
                        let showGroup = DispatchGroup()
                        
                        if showDocs.isEmpty {
                            showGroup.leave()
                        } else {
                            for showDoc in showDocs {
                                let showID = showDoc.documentID

                                showGroup.enter()
                                db.collection("users").document(userID).collection("tours").document(tourID).collection("shows").document(showID).collection("supportActs").getDocuments { supportSnap, _ in
                                    for supDoc in supportSnap?.documents ?? [] {
                                        let name = supDoc.data()["name"] as? String ?? ""
                                        collected.append(ContactModel(name: name, roles: ["Support Act"]))
                                    }
                                    showGroup.leave()
                                }

                                showGroup.enter()
                                db.collection("users").document(userID).collection("tours").document(tourID).collection("shows").document(showID).collection("guestlist").getDocuments { guestSnap, _ in
                                    for guestDoc in guestSnap?.documents ?? [] {
                                        let name = guestDoc.data()["name"] as? String ?? ""
                                        let note = guestDoc.data()["note"] as? String
                                        collected.append(ContactModel(name: name, roles: ["Guest"], notes: note))
                                    }
                                    showGroup.leave()
                                }
                            }
                        }

                        showGroup.notify(queue: .main) {
                            tourGroup.leave()
                        }
                    }
                }
            }
            
            tourGroup.notify(queue: .main) {
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.contacts = collected
            self.isLoading = false
        }
    }
}
