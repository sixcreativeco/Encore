import SwiftUI

struct MarketingTabView: View {
    var body: some View {
        VStack {
            Image(systemName: "megaphone.fill")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("Marketing & Promotion")
                .font(.title2.bold())
                .padding(.top)
            Text("This section will offer tools for event promotion and customer engagement.")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
