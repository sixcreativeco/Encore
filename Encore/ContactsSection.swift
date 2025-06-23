import SwiftUI
import FirebaseFirestore

struct ContactsSection: View {
    let userID: String
    let searchText: String
    let selectedFilter: String
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
        let filteredByRole = unifiedContacts.filter { contact in
            selectedFilter == "All" || contact.roles.contains(selectedFilter)
        }
        
        let filteredBySearch = filteredByRole.filter { contact in
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

        group.notify(queue: .main) {
            self.unifiedContacts = allContacts
            self.isLoading = false
        }
    }
}
