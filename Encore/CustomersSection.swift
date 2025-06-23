import SwiftUI
import FirebaseFirestore

struct CustomersSection: View {
    let userID: String
    let searchText: String
    let selectedFilter: String
    @Binding var sortField: String
    @Binding var sortAscending: Bool

    @State private var customers: [TicketSaleRowData] = []
    @State private var isLoading: Bool = true
    @State private var listener: ListenerRegistration?

    var body: some View {
        VStack {
            if isLoading {
                Spacer()
                ProgressView().progressViewStyle(.circular)
                Spacer()
            } else {
                CustomersTableView(customers: filteredCustomers, sortField: $sortField, sortAscending: $sortAscending)
            }
        }
        .onAppear(perform: setupListener)
        .onDisappear { listener?.remove() }
    }

    private var filteredCustomers: [TicketSaleRowData] {
        if searchText.isEmpty {
            return customers
        }
        return customers.filter {
            $0.buyerName.lowercased().contains(searchText.lowercased()) ||
            $0.buyerEmail.lowercased().contains(searchText.lowercased()) ||
            $0.eventDescription.lowercased().contains(searchText.lowercased())
        }
    }

    private func setupListener() {
        self.isLoading = true
        listener?.remove()
        
        let db = Firestore.firestore()
        
        // First, get all tours owned by the user to find the relevant tour IDs
        db.collection("tours").whereField("ownerId", isEqualTo: userID).getDocuments { tourSnapshot, error in
            guard let tourDocs = tourSnapshot?.documents else {
                self.isLoading = false
                return
            }
            
            let tourIDs = tourDocs.compactMap { $0.documentID }
            
            if tourIDs.isEmpty {
                self.customers = []
                self.isLoading = false
                return
            }
            
            // Now, listen for ticket sales related to those tours
            self.listener = db.collection("ticketSales")
                .whereField("tourId", in: tourIDs)
                .addSnapshotListener { snapshot, error in
                    guard let documents = snapshot?.documents else {
                        print("Error loading customers: \(error?.localizedDescription ?? "Unknown")")
                        self.isLoading = false
                        return
                    }
                    
                    self.customers = documents.map { TicketSaleRowData(from: $0) }
                    self.isLoading = false
                }
        }
    }
}
