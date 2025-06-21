import SwiftUI
import FirebaseFirestore

struct ContactsSection: View {
    let userID: String
    let searchText: String
    let selectedFilter: String
    @Binding var sortField: String
    @Binding var sortAscending: Bool

    // FIX: The state now uses our new, top-level 'Contact' model.
    @State private var contacts: [Contact] = []
    @State private var isLoading: Bool = true
    @State private var contactToEdit: Contact?
    
    // FIX: Add a listener registration state variable to manage its lifecycle.
    @State private var listener: ListenerRegistration?

    var body: some View {
        Group {
            if isLoading {
                VStack { Spacer(); ProgressView().progressViewStyle(.circular); Spacer() }
            } else {
                // This will cause a build error next, which is expected.
                // We will fix ContactsTableView in the next step.
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
        .onAppear(perform: setupListener)
        .onDisappear { listener?.remove() } // Clean up the listener
        .sheet(item: $contactToEdit) { contact in
            // This will cause a build error next, which is expected.
            // We will fix ContactEditView after we fix the table view.
            ContactEditView(contact: contact)
        }
    }

    private var filteredAndSorted: [Contact] {
        // This filtering logic is now much simpler.
        let filteredByRole = contacts.filter { contact in
            selectedFilter == "All" || contact.roles.contains(selectedFilter)
        }
        
        let filteredBySearch = filteredByRole.filter { contact in
            searchText.isEmpty ||
            contact.name.lowercased().contains(searchText.lowercased()) ||
            (contact.email ?? "").lowercased().contains(searchText.lowercased()) ||
            contact.roles.joined(separator: " ").lowercased().contains(searchText.lowercased())
        }
        
        // Sorting logic can be simplified if needed, but this works.
        return filteredBySearch.sorted { lhs, rhs in
            let lhsValue = sortFieldValue(lhs)
            let rhsValue = sortFieldValue(rhs)
            return sortAscending ? lhsValue < rhsValue : lhsValue > rhsValue
        }
    }
    
    private func sortFieldValue(_ contact: Contact) -> String {
        switch sortField {
        case "Name": return contact.name
        case "Role": return contact.roles.joined()
        case "Email": return contact.email ?? ""
        case "Phone": return contact.phone ?? ""
        default: return contact.name
        }
    }

    // --- FIX IS HERE ---
    private func setupListener() {
        self.isLoading = true
        listener?.remove() // Prevent duplicate listeners
        
        let db = Firestore.firestore()
        
        // This is now ONE simple, efficient query to the top-level /contacts collection.
        // It only fetches contacts created by the current user.
        listener = db.collection("contacts")
            .whereField("ownerId", isEqualTo: userID)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error loading contacts: \(error?.localizedDescription ?? "Unknown")")
                    self.isLoading = false
                    return
                }
                
                // We use Codable to automatically decode into our new [Contact] model.
                self.contacts = documents.compactMap { try? $0.data(as: Contact.self) }
                self.isLoading = false
            }
    }
}
