import SwiftUI
import Kingfisher
import FirebaseAuth

struct MyAccountView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var syncManager = OfflineSyncManager.shared
    @StateObject private var viewModel = MyAccountViewModel()

    @State private var userName: String = Auth.auth().currentUser?.displayName ?? "Loading..."
    @State private var userEmail: String = Auth.auth().currentUser?.email ?? ""

    var body: some View {
        ZStack {
            #if os(iOS)
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0/255, green: 58/255, blue: 83/255), Color(red: 23/255, green: 17/255, blue: 17/255)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            #endif
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    #if os(macOS)
                    Text("Account")
                        .font(.largeTitle.bold())
                    #endif

                    // --- THIS IS THE TEMPORARY ADMIN TOOL ---
                    // Run the app, navigate to this screen, and press the button inside this view.
                    // Once the script is complete, you can remove this line.
                    AdminBackfillView()
                    // ------------------------------------------

                    accountCard
                    stripeSection
                    supportSection

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Account")
            #if os(iOS)
            .background(Color.clear)
            #endif
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    private var accountCard: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    KFImage(Auth.auth().currentUser?.photoURL)
                        .placeholder {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(userName)
                            .font(.title2.bold())
                        Text("userid: \(appState.userID ?? "N/A")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                
                Label(userEmail, systemImage: "envelope.fill")
                    .font(.subheadline)
                
                Divider()
                
                HStack {
                    Text("Encore Indie Plan")
                        .font(.headline.bold())
                    Spacer()
                    HStack {
                        Circle()
                            .fill(syncManager.isOnline ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(syncManager.isOnline ? "Online" : "Offline")
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(.thinMaterial)
            .cornerRadius(16)
            
            ThemeSwitchView(selectedTheme: $themeManager.selectedTheme)
                .padding(8)
        }
    }
    
    @ViewBuilder
    private var stripeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payments")
                .font(.title2.bold())
            
            VStack(alignment: .leading) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 150)
                } else if viewModel.hasStripeAccount, let status = viewModel.stripeAccountStatus {
                    connectedStripeView(status: status)
                } else {
                    disconnectedStripeView
                }
            }
            .padding()
            .background(.thinMaterial)
            .cornerRadius(16)
        }
    }
    
    private var disconnectedStripeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Stripe Account Not Connected", systemImage: "xmark.circle.fill")
                .font(.headline)
                .foregroundColor(.orange)
            
            Text("Connect a Stripe account to start selling tickets and receive payouts directly to your bank account.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                viewModel.connectStripeAccount()
            }) {
                Text("Connect Stripe Account")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(color: .blue))
        }
    }
    
    private func connectedStripeView(status: MyAccountViewModel.StripeAccountStatus) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Stripe Account Connected", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Account ID: \(status.accountId)")
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
                
                statusRow(label: "Onboarding Complete", condition: status.detailsSubmitted)
                statusRow(label: "Payments Enabled", condition: status.chargesEnabled)
                statusRow(label: "Payouts Enabled", condition: status.payoutsEnabled)
            }
            
            Button("Disconnect Stripe Account", role: .destructive) {
                Task {
                    await viewModel.disconnectStripeAccount()
                }
            }
            .buttonStyle(PrimaryButtonStyle(color: .red.opacity(0.8)))
        }
    }
    
    private func statusRow(label: String, condition: Bool) -> some View {
        HStack {
            Image(systemName: condition ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(condition ? .green : .orange)
            Text(label)
            Spacer()
        }
        .font(.subheadline)
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Support")
                .font(.title2.bold())
            
            VStack(spacing: 12) {
                supportButton(title: "Contact Support") {}
                supportButton(title: "Terms of Service") {}
                supportButton(title: "Privacy Policy") {}
            }
            
            Button("Sign Out", role: .destructive) {
                AuthManager.shared.signOut()
            }
            .buttonStyle(PrimaryButtonStyle(color: .red.opacity(0.7)))
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
        }
    }

    private func supportButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 10)
                .background(.thinMaterial)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
