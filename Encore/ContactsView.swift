import SwiftUI
import FirebaseFirestore

struct ContactsView: View {
    let userID: String

    @State private var contacts: [ContactModel] = []
    @State private var isLoading: Bool = true

    @State private var searchText: String = ""
    @State private var selectedFilter: String = "All"
    private let filters = ["All", "Artists", "Support Acts", "Crew", "Guests"]

    var filteredContacts: [ContactModel] {
        contacts.filter { contact in
            let matchesFilter = selectedFilter == "All" || contact.role == roleForFilter(selectedFilter)
            let matchesSearch = searchText.isEmpty || contact.name.lowercased().contains(searchText.lowercased())
            return matchesFilter && matchesSearch
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contacts")
                .font(.largeTitle.bold())
                .padding(.bottom, 10)

            HStack {
                StyledInputField(placeholder: "Search...", text: $searchText)
                    .frame(width: 300)
                Spacer()
                Text("Filter").foregroundColor(.gray)
                Picker("", selection: $selectedFilter) {
                    ForEach(filters, id: \.self) { filter in
                        Text(filter).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 400)
            }

            if isLoading {
                Spacer().frame(height: 100)
                ProgressView().progressViewStyle(.circular)
            } else if filteredContacts.isEmpty {
                Text("No contacts found").foregroundColor(.gray)
            } else {
                ScrollView {
                    ContactsTableView(contacts: filteredContacts)
                }
            }
        }
        .padding()
        .onAppear {
            loadContacts()
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

                    showGroup.notify(queue: .main) {
                        group.leave()
                    }
                }
            }

            group.notify(queue: .main) {
                self.contacts = deduplicate(collected)
                self.isLoading = false
            }
        }
    }

    private func deduplicate(_ models: [ContactModel]) -> [ContactModel] {
        var dict: [String: ContactModel] = [:]
        for model in models where !model.name.isEmpty {
            let key = model.id
            if let existing = dict[key] {
                dict[key] = ContactModel(
                    name: existing.name,
                    role: existing.role.isEmpty ? model.role : existing.role,
                    email: existing.email ?? model.email,
                    phone: existing.phone ?? model.phone,
                    notes: existing.notes ?? model.notes
                )
            } else {
                dict[key] = model
            }
        }
        return dict.values.sorted { $0.name < $1.name }
    }

    private func roleForFilter(_ filter: String) -> String {
        switch filter {
        case "Artists": return "Artist"
        case "Support Acts": return "Support Act"
        case "Crew": return "Crew"
        case "Guests": return "Guest"
        default: return ""
        }
    }
}
