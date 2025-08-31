import SwiftUI
import FirebaseFirestore

struct AddGuestView: View {
    // These properties are passed in when the view is created
    var userID: String
    var tourID: String
    var showID: String
    var onSave: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var numberOfTickets = "1"
    @State private var note = ""
    
    @State private var isSaving = false
    @State private var errorMessage: String?

    let windowWidth: CGFloat = 450

    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && (Int(numberOfTickets) ?? 0) > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Issue Comp Tickets").font(.largeTitle.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                         .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Guest Details").font(.headline)
                CustomInputField(placeholder: "Full Name*", text: $name)
                CustomInputField(placeholder: "Email Address*", text: $email)

                Text("Tickets").font(.headline)
                CustomInputField(placeholder: "Number of Tickets*", text: $numberOfTickets)
                
                Text("Note").font(.headline)
                CustomInputField(placeholder: "Optional note (e.g., for box office)", text: $note)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Spacer()

            Button(action: issueCompTickets) {
                HStack {
                    Spacer()
                    if isSaving {
                        ProgressView().colorInvert()
                    } else {
                        Text("Issue Complimentary Tickets")
                    }
                    Spacer()
                }
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.vertical, 12)
                .background(isFormValid ? Color.accentColor : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(!isFormValid || isSaving)
        }
        .padding(30)
        .frame(width: windowWidth)
        .frame(minHeight: 450)
    }

    private func issueCompTickets() {
        isSaving = true
        errorMessage = nil
        
        guard let quantity = Int(numberOfTickets), quantity > 0 else {
            errorMessage = "Please enter a valid number of tickets."
            isSaving = false
            return
        }

        // In the next step, we will create this TicketingAPI function.
        // For now, this prepares the view for that change.
        TicketingAPI.shared.issueCompTickets(
            showId: showID,
            name: name,
            email: email,
            quantity: quantity,
            note: note
        ) { result in
            isSaving = false
            switch result {
            case .success:
                print("✅ Comp tickets issued successfully via API.")
                onSave()
                dismiss()
            case .failure(let error):
                print("❌ Error issuing comp tickets: \(error.localizedDescription)")
                self.errorMessage = "Failed to issue tickets: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Reusable Input Field (Assuming this is in its own file or accessible)
fileprivate struct CustomInputField: View {
    var placeholder: String
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(inputBackgroundColor)
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
            }
            TextField("", text: $text)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.clear)
                .cornerRadius(8)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .frame(height: 38)
    }

    private var inputBackgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 50/255, green: 50/255, blue: 50/255)
            : Color(red: 240/255, green: 240/255, blue: 240/255)
    }
}
