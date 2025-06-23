import SwiftUI
import FirebaseFirestore

// Definition copied from TicketsViewModel to make this view self-contained
struct TicketSaleRowData: Identifiable {
    let id: String
    let eventDescription: String
    let buyerName: String
    let buyerEmail: String
    let buyerPhone: String
    let purchaseDate: Date
    
    init(from sale: DocumentSnapshot) {
        let data = sale.data() ?? [:]
        self.id = sale.documentID
        self.eventDescription = data["eventDescription"] as? String ?? "N/A"
        self.buyerName = data["buyerName"] as? String ?? "N/A"
        self.buyerEmail = data["buyerEmail"] as? String ?? "N/A"
        self.buyerPhone = data["buyerPhone"] as? String ?? "N/A"
        self.purchaseDate = (data["purchaseDate"] as? Timestamp)?.dateValue() ?? Date()
    }
}

struct CustomersTableView: View {
    let customers: [TicketSaleRowData]
    @Binding var sortField: String
    @Binding var sortAscending: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    sortableHeader("Name")
                    sortableHeader("Email")
                    sortableHeader("Phone")
                    sortableHeader("Purchase Date")
                }
                .padding(.vertical, 8)
                Divider()

                ForEach(sortedCustomers) { customer in
                    HStack {
                        Text(customer.buyerName).frame(maxWidth: .infinity, alignment: .leading)
                        Text(customer.buyerEmail).frame(maxWidth: .infinity, alignment: .leading)
                        Text(customer.buyerPhone).frame(maxWidth: .infinity, alignment: .leading)
                        Text(customer.purchaseDate.formatted(date: .abbreviated, time: .omitted)).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
            .padding(.horizontal)
        }
    }

    private var sortedCustomers: [TicketSaleRowData] {
        customers.sorted { a, b in
            let comparison: Bool
            switch sortField {
            case "Name":
                comparison = a.buyerName < b.buyerName
            case "Email":
                comparison = a.buyerEmail < b.buyerEmail
            case "Purchase Date":
                comparison = a.purchaseDate < b.purchaseDate
            default:
                comparison = a.purchaseDate < b.purchaseDate
            }
            return sortAscending ? comparison : !comparison
        }
    }

    private func sortableHeader(_ field: String) -> some View {
        Button(action: {
            if sortField == field {
                sortAscending.toggle()
            } else {
                sortField = field
                sortAscending = true
            }
        }) {
            HStack {
                Text(field).bold()
                if sortField == field {
                    Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}
