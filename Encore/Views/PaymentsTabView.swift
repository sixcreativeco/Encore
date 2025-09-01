import SwiftUI
import Kingfisher

struct PaymentsTabView: View {
    @ObservedObject var viewModel: TicketsViewModel
    @State private var showingPayoutSheet = false
    
    @State private var refundSearchText: String = ""
    @State private var selectedSaleIDs = Set<String>()
    @State private var isShowingRefundAlert = false
    @State private var saleToRefund: TicketsViewModel.TicketSale?

    private let columns = [
        GridItem(.fixed(300), spacing: 24, alignment: .top),
        GridItem(.flexible(), spacing: 24, alignment: .top)
    ]
    
    private var filteredSales: [TicketsViewModel.TicketSale] {
        let sortedSales = viewModel.allTicketSales.sorted { $0.purchaseDate > $1.purchaseDate }
        if refundSearchText.isEmpty {
            return sortedSales
        }
        return sortedSales.filter {
            $0.buyerName.lowercased().contains(refundSearchText.lowercased()) ||
            $0.buyerEmail.lowercased().contains(refundSearchText.lowercased())
        }
    }

    var body: some View {
        ScrollView {
            // --- THIS IS THE FIX ---
            // The incorrect 'alignment: .top' parameter has been removed from the LazyVGrid.
            // The vertical alignment is correctly handled by the `.top` setting in the `columns` property above.
            LazyVGrid(columns: columns, spacing: 24) {
                // Left Column: Balances and Account Status
                VStack(spacing: 24) {
                    balanceCards
                    stripeAccountCard
                }
                
                // Right Column: Transaction History
                refundsSection
            }
        }
        .sheet(isPresented: $showingPayoutSheet) {
            StripePayoutRequestView(viewModel: viewModel)
        }
        .alert("Confirm Refund", isPresented: $isShowingRefundAlert, presenting: saleToRefund) { sale in
            Button("Refund \(sale.buyerName)", role: .destructive) {
                Task {
                    await viewModel.issueRefund(for: sale.purchaseId)
                }
            }
        } message: { sale in
            Text("Are you sure you want to issue a full refund for this ticket? This action cannot be undone.")
        }
    }
    
    private var balanceCards: some View {
        VStack(spacing: 16) {
            balanceCard(title: "Pending Balance", amount: viewModel.stripePendingBalance, currency: viewModel.stripeCurrency, icon: "clock", iconColor: .orange)
            balanceCard(title: "Available for Payout", amount: viewModel.stripeBalance, currency: viewModel.stripeCurrency, icon: "creditcard", iconColor: .green) {
                if viewModel.hasStripeAccount {
                    Button("Request Payout") { showingPayoutSheet = true }
                    .buttonStyle(PrimaryButtonStyle(color: .white, textColor: .black))
                    .disabled(viewModel.stripeBalance <= 0)
                }
            }
        }
    }
    
    @ViewBuilder
    private func balanceCard<Footer: View>(title: String, amount: Double, currency: String, icon: String, iconColor: Color, @ViewBuilder footer: () -> Footer = { EmptyView() }) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundColor(iconColor)
                Text(title).font(.subheadline).foregroundColor(.secondary)
            }
            HStack(alignment: .bottom) {
                Text("\(currency) \(String(format: "%.2f", amount))").font(.title.bold()).foregroundColor(amount > 0 ? iconColor : .primary)
                Spacer()
                footer()
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).background(Material.regular).cornerRadius(12)
    }
    
    private var stripeAccountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stripe Account")
                .font(.title2.bold())
            
            VStack(alignment: .leading) {
                if viewModel.hasStripeAccount {
                    statusRow(label: "Account Connected", condition: true)
                    
                    Button(action: {
                        if let stripeId = viewModel.stripeAccountId, !stripeId.isEmpty,
                           let url = URL(string: "https://connect.stripe.com/app/express/\(stripeId)") {
                           NSWorkspace.shared.open(url)
                        }
                    }) {
                        Text("Stripe Dashboard")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.top, 8)
                    
                } else {
                    Text("Connect a Stripe account to start receiving payouts.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Setup Stripe Account") {
                        viewModel.setupStripeAccount()
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .blue))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Material.regular)
            .cornerRadius(12)
        }
    }
    
    private func statusRow(label: String, condition: Bool) -> some View {
        HStack {
            Image(systemName: condition ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(condition ? .green : .red)
            Text(label)
        }
    }
    
    private var refundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transactions & Refunds").font(.title2.bold())
            
            HStack {
                StyledInputField(placeholder: "Search by name or email...", text: $refundSearchText)
            }
            
            VStack(alignment: .leading) {
                if viewModel.allTicketSales.isEmpty {
                    Text("No transactions yet.").foregroundColor(.secondary).frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    ForEach(filteredSales, id: \.purchaseId) { sale in
                        TransactionRowView(sale: sale, viewModel: viewModel) {
                            self.saleToRefund = sale
                            self.isShowingRefundAlert = true
                        }
                        Divider()
                    }
                }
            }
            .padding().background(Material.regular).cornerRadius(12)
        }
    }
}

fileprivate struct TransactionRowView: View {
    let sale: TicketsViewModel.TicketSale
    @ObservedObject var viewModel: TicketsViewModel
    var onRefund: () -> Void
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter(); formatter.numberStyle = .currency; formatter.currencyCode = sale.currency; return formatter
    }
    
    private var show: Show? {
        viewModel.allShows.first { $0.id == sale.showId }
    }
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                Text(sale.buyerName).fontWeight(.semibold)
                Text(sale.buyerEmail).font(.subheadline).foregroundColor(.secondary)
                Text("Purchased \(sale.quantity) x \(sale.ticketTypeName) for \(show?.city ?? "event")")
                    .font(.caption).foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(currencyFormatter.string(from: NSNumber(value: sale.totalPrice)) ?? "").fontWeight(.semibold)
                Text(sale.purchaseDate, style: .date).font(.caption).foregroundColor(.secondary)
            }
            
            if sale.status == "completed" {
                Button("Refund", role: .destructive, action: onRefund)
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(viewModel.isRefunding)
            } else {
                Text(sale.status.capitalized)
                    .font(.caption.bold())
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.secondary)
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 8)
    }
}
