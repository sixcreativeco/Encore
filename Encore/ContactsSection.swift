import SwiftUI
import FirebaseFirestore

struct ContactsSection: View {
    let userID: String
    let searchText: String
    let hideGuests: Bool
    @Binding var sortField: String
    @Binding var sortAscending: Bool

    @State private var unifiedContacts: [UnifiedContact] = []
    @State private var isLoading: Bool = true
    @State private var contactToEdit: Contact?
    var body: some View {
        Group {
            if isLoading {
                VStack { Spacer(); ProgressView().progressViewStyle(.circular); Spacer() }
            } else {
                ContactsTableView(
                    contacts: filteredAndSorted,
                    sortField: $sortField,
                    sortAscending: $sortAscending,
                    onContactSelected: { unifiedContact in
                        // Future navigation to a unified detail view can be handled here.
                        // For now, only contacts from the 'contacts' source can be edited.
                        if unifiedContact.source == "Contacts" {
                             // This part needs a fuller implementation to fetch the original Contact model for editing.
                        }
                    }
                )
            }
        }
        .onAppear(perform: fetchAndMergeContacts)
        .sheet(item: $contactToEdit) { contact in
            ContactEditView(contact: contact)
        }
    }

    private var filteredAndSorted: [UnifiedContact] {
        var filtered = unifiedContacts
        
        if hideGuests {
            filtered = filtered.filter { $0.source != "Guest List" }
        }
        
        let filteredBySearch = filtered.filter { contact in
            searchText.isEmpty ||
            contact.name.lowercased().contains(searchText.lowercased()) ||
            (contact.email ?? "").lowercased().contains(searchText.lowercased()) ||
            contact.roles.joined(separator: " ").lowercased().contains(searchText.lowercased())
        }
        
        return filteredBySearch.sorted { lhs, rhs in
            let lhsValue: String
            switch sortField {
            case "Name": lhsValue = lhs.name
            case "Role": lhsValue = lhs.roles.joined()
            case "Email": lhsValue = lhs.email ?? ""
            case "Phone": lhsValue = lhs.phone ?? ""
            case "Source": lhsValue = lhs.source
            default: lhsValue = lhs.name
            }

            let rhsValue: String
            switch sortField {
            case "Name": rhsValue = rhs.name
            case "Role": rhsValue = rhs.roles.joined()
            case "Email": rhsValue = rhs.email ?? ""
            case "Phone": rhsValue = rhs.phone ?? ""
            case "Source": rhsValue = rhs.source
            default: rhsValue = rhs.name
            }
            return sortAscending ? lhsValue < rhsValue : lhsValue > rhsValue
        }
    }
    
    private func fetchAndMergeContacts() {
        self.isLoading = true
        
        let db = Firestore.firestore()
        let group = DispatchGroup()
        var allContacts: [UnifiedContact] = []
        var seenEmails = Set<String>()

        
        // 1. Fetch from main 'contacts' collection
        group.enter()
        db.collection("contacts").whereField("ownerId", isEqualTo: userID).getDocuments { snapshot, _ in
            let contacts = snapshot?.documents.compactMap { try? $0.data(as: Contact.self) } ?? []
            for contact in contacts {
                if let email = contact.email, !email.isEmpty, seenEmails.contains(email) { continue }
                allContacts.append(UnifiedContact(id: contact.id ?? UUID().uuidString, name: contact.name, email: contact.email, phone: contact.phone, roles: contact.roles, source: "Contacts"))
                if let email = contact.email, !email.isEmpty { seenEmails.insert(email) }
            }
            group.leave()
        }

        // 2. Fetch from 'venues' collection
        group.enter()
        db.collection("venues").whereField("ownerId", isEqualTo: userID).getDocuments { snapshot, _ in
            let venues = snapshot?.documents.compactMap { try? $0.data(as: Venue.self) } ?? []
            for venue in venues {
                guard let name = venue.contactName, !name.isEmpty else { continue }
                if let email = venue.contactEmail, !email.isEmpty, seenEmails.contains(email) { continue }
                allContacts.append(UnifiedContact(id: venue.id ?? UUID().uuidString, name: name, email: venue.contactEmail, phone: venue.contactPhone, roles: ["Venue Contact"], source: "Venues"))
                if let email = venue.contactEmail, !email.isEmpty { seenEmails.insert(email) }
            }
            group.leave()
        }

        // 3. Fetch from 'tourCrew' collection
        group.enter()
        db.collection("tourCrew").whereField("invitedBy", isEqualTo: userID).getDocuments { snapshot, _ in
            let crew = snapshot?.documents.compactMap { try? $0.data(as: TourCrew.self) } ?? []
            for member in crew {
                if let email = member.email, !email.isEmpty, seenEmails.contains(email) { continue }
                allContacts.append(UnifiedContact(id: member.id ?? UUID().uuidString, name: member.name, email: member.email, phone: nil, roles: member.roles, source: "Tour Crew"))
                if let email = member.email, !email.isEmpty { seenEmails.insert(email) }
            }
            group.leave()
        }
        
        // 4. Fetch Guests
        group.enter()
        fetchGuests { guests in
            for guest in guests {
                // Assuming guest names are unique enough for this view's purpose
                allContacts.append(guest)
            }
            group.leave()
        }

        group.notify(queue: .main) {
            self.unifiedContacts = allContacts
            self.isLoading = false
        }
    }
    
    private func fetchGuests(completion: @escaping ([UnifiedContact]) -> Void) {
        let db = Firestore.firestore()
        var guestContacts: [UnifiedContact] = []
        
        // Step 1: Find all tours owned by the current user
        db.collection("tours").whereField("ownerId", isEqualTo: userID).getDocuments { toursSnapshot, error in
            guard let tourDocs = toursSnapshot?.documents, !tourDocs.isEmpty else {
                completion([])
                return
            }
            let tourIDs = tourDocs.compactMap { $0.documentID }

            // Step 2: Find all shows associated with those tours
            db.collection("shows").whereField("tourId", in: tourIDs).getDocuments { showsSnapshot, error in
                guard let showDocs = showsSnapshot?.documents, !showDocs.isEmpty else {
                    completion([])
                    return
                }

                let group = DispatchGroup()
                
                // Step 3: For each show, fetch its guest list
                for showDoc in showDocs {
                    guard let tourId = showDoc["tourId"] as? String else { continue }
                    group.enter()
                    // The path to guestlist is nested under users, which is not ideal for querying.
                    // This path assumes a different structure, let's correct it based on AddGuestView
                    // Correct Path: db.collection("users").document(userID)...
                    // This is inefficient. A collectionGroup query on 'guestlist' would be better,
                    // but requires adding 'ownerId' to each guest document.
                    // Using the existing inefficient path:
                    db.collection("users").document(self.userID).collection("tours").document(tourId).collection("shows").document(showDoc.documentID).collection("guestlist").getDocuments { guestSnapshot, error in
                        
                        let guests = guestSnapshot?.documents.compactMap { GuestListItemModel(from: $0) } ?? []
                        for guest in guests {
                            let roles = ["Guest"]
                            let contact = UnifiedContact(id: guest.id, name: guest.name, email: nil, phone: nil, roles: roles, source: "Guest List")
                            guestContacts.append(contact)
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    completion(guestContacts)
                }
            }
        }
    }
}
