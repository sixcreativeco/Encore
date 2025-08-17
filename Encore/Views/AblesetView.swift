import SwiftUI

struct AblesetView: View {
    @State private var urlString: String = ""
    @State private var urlToLoad: URL?
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header for input and controls
            HStack(spacing: 16) {
                Button(action: {
                    appState.showingAbleset = false
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back to Show")
                    }
                    .font(.system(size: 13, weight: .medium)).foregroundColor(.primary)
                    .padding(.vertical, 6).padding(.horizontal, 12)
                    .background(Color.black.opacity(0.15)).cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()

                CustomTextField(placeholder: "Enter Ableset IP Address or URL...", text: $urlString)
                    .onSubmit(connect)
                    .frame(maxWidth: 450)

                Button("Connect", action: connect)
                    .buttonStyle(PrimaryButtonStyle(color: .accentColor))
                    .disabled(urlString.isEmpty)
            }
            .padding(.horizontal, 30)
            .padding(.top, 30)

            // Main content area
            ZStack {
                if let url = urlToLoad {
                    WebView(url: url)
                        .cornerRadius(16)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 30)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "network.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Not Connected to Ableset")
                            .font(.title2.bold())
                        Text("Enter the local IP address or domain for Ableset and press 'Connect'.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                    }
                    .padding(40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.thinMaterial)
                    .cornerRadius(16)
                    .padding(30)
                }
            }
        }
    }

    private func connect() {
        var correctedUrlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !correctedUrlString.hasPrefix("http://") && !correctedUrlString.hasPrefix("https://") {
            correctedUrlString = "http://" + correctedUrlString
        }

        guard let url = URL(string: correctedUrlString) else {
            print("Invalid URL entered: \(correctedUrlString)")
            return
        }
        self.urlToLoad = url
    }
}
