import SwiftUI

struct StripePayoutRequestView: View {
    @ObservedObject var viewModel: TicketsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var payoutAmount: String = ""
    @State private var selectedQuickAmount: Double? = nil
    
    private var availableBalance: Double {
        viewModel.stripeBalance
    }
    
    private var currency: String {
        viewModel.stripeCurrency
    }
    
    private var payoutAmountDouble: Double {
        Double(payoutAmount) ?? 0.0
    }
    
    private var isValidAmount: Bool {
        let amount = payoutAmountDouble
        return amount > 0 && amount <= availableBalance
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                
                if availableBalance > 0 {
                    quickAmountSection
                    customAmountSection
                }
                
                informationSection
                
                Spacer(minLength: 20)
                
                actionButtonsSection
            }
            .padding(24)
        }
        .frame(width: 500, height: 600)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Request Payout")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Available Balance: \(currency) \(String(format: "%.2f", availableBalance))")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    private var quickAmountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Amounts")
                .font(.headline)
            
            let quickAmounts = generateQuickAmounts()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(quickAmounts, id: \.self) { amount in
                    quickAmountButton(for: amount)
                }
            }
        }
    }
    
    private func quickAmountButton(for amount: Double) -> some View {
        Button(action: {
            selectedQuickAmount = amount
            payoutAmount = String(format: "%.2f", amount)
        }) {
            VStack(spacing: 4) {
                if amount == availableBalance {
                    Text("All")
                        .font(.system(size: 14, weight: .semibold))
                    Text("\(currency) \(String(format: "%.2f", amount))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(currency) \(String(format: "%.0f", amount))")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selectedQuickAmount == amount ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedQuickAmount == amount ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var customAmountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom Amount")
                .font(.headline)
            
            HStack {
                Text(currency)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("0.00", text: $payoutAmount)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: payoutAmount) { _ in
                        selectedQuickAmount = nil
                    }
            }
        }
    }
    
    private var informationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payout Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• Payouts are processed directly by Stripe")
                Text("• Funds typically arrive within 1-2 business days")
                Text("• You'll receive an email confirmation once processed")
                Text("• Minimum payout amount may apply")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(SecondaryButtonStyle())
            
            Button(action: {
                viewModel.requestStripePayout(amount: payoutAmountDouble)
                dismiss()
            }) {
                if viewModel.isRequestingPayout {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Processing...")
                    }
                } else {
                    Text("Request Payout")
                }
            }
            .buttonStyle(PrimaryButtonStyle(color: .blue, isLoading: viewModel.isRequestingPayout))
            .disabled(!isValidAmount || viewModel.isRequestingPayout)
        }
    }
    
    private func generateQuickAmounts() -> [Double] {
        let balance = availableBalance
        var amounts: [Double] = []
        
        if balance >= 50 {
            amounts.append(50)
        }
        if balance >= 100 {
            amounts.append(100)
        }
        if balance >= 250 {
            amounts.append(250)
        }
        if balance >= 500 {
            amounts.append(500)
        }
        
        if balance > 0 {
            amounts.append(balance)
        }
        
        return amounts
    }
}

#Preview {
    StripePayoutRequestView(viewModel: TicketsViewModel(userID: "test"))
}
