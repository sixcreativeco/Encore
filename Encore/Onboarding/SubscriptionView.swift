import SwiftUI

// MARK: - Models for Subscription View

/// Defines the billing cycle options.
enum BillingCycle: String, CaseIterable {
    case monthly = "Monthly"
    case annually = "Annually"
}

/// Represents a single subscription plan with its details.
fileprivate struct SubscriptionPlan: Identifiable {
    let id: String
    let title: String
    let priceMonthly: String
    let priceAnnually: String
    let features: [String]
    let isFree: Bool
    
    var pricePerMonthAnnually: String? {
        // A simple calculation for "per month" price on annual plan
        guard let annualPriceValue = Double(priceAnnually.filter("0123456789.".contains)) else {
            return nil
        }
        let monthlyEquivalent = annualPriceValue / 12
        return String(format: "$%.2f", monthlyEquivalent)
    }
}

// MARK: - Main Subscription View

struct SubscriptionView: View {
    
    // State & Bindings
    @State private var selectedCycle: BillingCycle = .monthly
    @State private var selectedPlanID: String?
    
    // Properties
    let recommendedPlanID: String
    var onContinue: (String, BillingCycle) -> Void
    
    // Plan Definitions
    private let plans: [SubscriptionPlan] = [
        SubscriptionPlan(id: "Indie Artist", title: "Indie Artist", priceMonthly: "$0", priceAnnually: "$0", features: ["1 Tour at a time", "Unlimited Shows", "Full Itinerary Management", "Core Export Features"], isFree: true),
        SubscriptionPlan(id: "Artist Pro", title: "Artist Pro", priceMonthly: "$25", priceAnnually: "$250", features: ["Unlimited Tours", "Advanced Exports & Themes", "Ticketing Integration (5% fee)", "Priority Support"], isFree: false),
        SubscriptionPlan(id: "Indie Agency", title: "Indie Agency", priceMonthly: "$75", priceAnnually: "$750", features: ["Manage up to 5 Artists", "Team Member Access", "Branded Exports", "Ticketing Integration (5% fee)"], isFree: false),
        SubscriptionPlan(id: "Agency Pro", title: "Agency Pro", priceMonthly: "$150", priceAnnually: "$1500", features: ["Manage Unlimited Artists", "Advanced Team Permissions", "White-Label Solutions", "Reduced Ticketing Fee (2.5%)"], isFree: false)
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            header
            billingCycleToggle
            plansGrid
            Spacer()
            continueButton
        }
        .padding(32)
        .onAppear {
            self.selectedPlanID = recommendedPlanID
        }
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        VStack(spacing: 8) {
            Text("Choose Your Plan")
                .font(.largeTitle.bold())
            Text("Select a plan that best fits your needs. You can upgrade or downgrade at any time.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
    }
    
    private var billingCycleToggle: some View {
        HStack {
            ForEach(BillingCycle.allCases, id: \.self) { cycle in
                Button(action: {
                    withAnimation(.easeInOut) {
                        selectedCycle = cycle
                    }
                }) {
                    Text(cycle.rawValue)
                        .font(.headline)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(selectedCycle == cycle ? Color.accentColor : Color.clear)
                        .foregroundColor(selectedCycle == cycle ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.gray.opacity(0.2))
        .clipShape(Capsule())
        .frame(width: 250)
    }
    
    private var plansGrid: some View {
        HStack(spacing: 16) {
            ForEach(plans) { plan in
                planCard(plan: plan)
            }
        }
        .padding(.top)
    }
    
    private func planCard(plan: SubscriptionPlan) -> some View {
        let isSelected = plan.id == selectedPlanID
        let isRecommended = plan.id == recommendedPlanID
        
        return VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading) {
                Text(plan.title)
                    .font(.title2.bold())
                
                HStack(alignment: .bottom, spacing: 2) {
                    Text(selectedCycle == .monthly ? plan.priceMonthly : plan.priceAnnually)
                        .font(.system(size: 32, weight: .bold))
                    
                    if !plan.isFree {
                        Text(selectedCycle == .monthly ? "/ month" : "/ year")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                    }
                }
                
                if selectedCycle == .annually, let perMonth = plan.pricePerMonthAnnually, !plan.isFree {
                    Text("or \(perMonth) per month")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Features
            VStack(alignment: .leading, spacing: 10) {
                ForEach(plan.features, id: \.self) { feature in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(feature)
                            .font(.subheadline)
                    }
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.gray.opacity(isSelected ? 0.2 : 0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .overlay(alignment: .top) {
            if isRecommended {
                Text("RECOMMENDED")
                    .font(.system(size: 10, weight: .heavy))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .offset(y: -12)
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut) {
                selectedPlanID = plan.id
            }
        }
    }
    
    private var continueButton: some View {
        Button(action: {
            guard let selectedPlanID = selectedPlanID else { return }
            onContinue(selectedPlanID, selectedCycle)
        }) {
            Text("Continue")
                .font(.headline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedPlanID != nil ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(selectedPlanID == nil)
    }
}
