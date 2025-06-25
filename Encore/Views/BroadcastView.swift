import SwiftUI

struct BroadcastView: View {
    let tour: Tour
    @Environment(\.dismiss) var dismiss

    @State private var message: String = ""
    @State private var isSending: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Broadcast to Crew")
                    .font(.largeTitle.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }

            Text("Your message will be sent as a push notification to all registered crew members on **\(tour.tourName)**.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            CustomTextEditor(placeholder: "Type your message here...", text: $message)
                .frame(minHeight: 150, maxHeight: 300)

            Spacer()

            if let error = errorMessage {
                Text("Failed to send: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Button(action: sendBroadcast) {
                HStack {
                    Spacer()
                    if isSending {
                        ProgressView()
                            .colorInvert()
                    } else {
                        Text("Send Broadcast")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .buttonStyle(PrimaryButtonStyle(color: .accentColor, isLoading: isSending))
            .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(30)
        .frame(minWidth: 500, minHeight: 400)
    }

    private func sendBroadcast() {
        guard let tourId = tour.id else {
            self.errorMessage = "This tour has an invalid ID."
            return
        }
        
        isSending = true
        errorMessage = nil

        NotificationService.shared.sendBroadcast(to: tourId, with: message) { error in
            isSending = false
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                dismiss()
            }
        }
    }
}
