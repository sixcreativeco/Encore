import SwiftUI

struct PayoutRequestView: View {
    let availableBalance: Double
    let currency: String
    let onRequestPayout: (Double) -> Void
    
    @State private var payoutAmount: String = ""
    @State private var isValidAmount: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter
    }
    
    private var requestedAmount: Double {
        Double(payoutAmount) ?? 0.0
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                Text("Request Payout")
                    .font(.title)
                    .bold()
                
                Text("Withdraw your earnings to your bank account")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Available Balance
            VStack(spacing: 4) {
                Text("Available Balance")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(currencyFormatter.string(from: NSNumber(value: availableBalance)) ?? "$0.00")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.green)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
            // Amount Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Payout Amount")
                    .font(.headline)
                
                HStack {
                    Text(currency)
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    TextField("0.00", text: $payoutAmount)
                        .font(.title2)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: payoutAmount) { _ in
                            validateAmount()
                        }
                }
                
                if !isValidAmount && !payoutAmount.isEmpty {
                    Text("Amount must be between $1.00 and \(currencyFormatter.string(from: NSNumber(value: availableBalance)) ?? "$0.00")")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Quick Amount Buttons
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Select")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    if availableBalance >= 50 {
                        Button("$50") {
                            payoutAmount = "50"
                            validateAmount()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if availableBalance >= 100 {
                        Button("$100") {
                            payoutAmount = "100"
                            validateAmount()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if availableBalance > 0 {
                        Button("All (\(currencyFormatter.string(from: NSNumber(value: availableBalance)) ?? "$0.00"))") {
                            payoutAmount = String(format: "%.2f", availableBalance)
                            validateAmount()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button("Request Payout") {
                    onRequestPayout(requestedAmount)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidAmount)
                .controlSize(.large)
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(width: 400, height: 600)
        .navigationTitle("Request Payout")
    }
    
    private func validateAmount() {
        let amount = Double(payoutAmount) ?? 0.0
        isValidAmount = amount >= 1.0 && amount <= availableBalance
    }
}

#Preview {
    PayoutRequestView(
        availableBalance: 250.50,
        currency: "NZD",
        onRequestPayout: { amount in
            print("Requesting payout of $\(amount)")
        }
    )
}
