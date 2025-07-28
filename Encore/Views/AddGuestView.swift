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
    @State private var additionalGuests = ""
    @State private var note = ""

    let windowWidth: CGFloat = 450

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Add Guest").font(.largeTitle.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }

            // Form fields for guest details
            VStack(alignment: .leading, spacing: 16) {
                Text("Guest").font(.headline)
                HStack(spacing: 12) {
                    CustomInputField(placeholder: "Name", text: $name)
                    Text("+").font(.title2.bold())
                    CustomInputField(placeholder: "0", text: $additionalGuests)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Note").font(.headline)
                    CustomInputField(placeholder: "Optional note", text: $note)
                }
            }

            // Save button
            Button(action: { saveGuest() }) {
                Text("Save Guest")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(name.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(name.isEmpty)
            
            Spacer()
        }
        .padding(30)
        .frame(width: windowWidth) // Chained modifier
        .frame(minHeight: 350)     // Chained modifier
    }

    private func saveGuest() {
        let db = Firestore.firestore()
        
        let guestlistRef = db.collection("shows").document(showID).collection("guestlist")
        
        let data: [String: Any] = [
            "name": name,
            "additionalGuests": additionalGuests,
            "note": note,
            "showId": showID,
            "tourId": tourID,
            "ownerId": userID,
            "isCheckedIn": false,
            "createdAt": Timestamp(date: Date())
        ]
        
        print("INFO: Attempting to save guest '\(name)' to showId: \(showID)...")

        guestlistRef.addDocument(data: data) { error in
            if let error = error {
                print("❌ Error saving guest: \(error.localizedDescription)")
            } else {
                print("✅ Guest '\(name)' saved successfully.")
                onSave()
                dismiss()
            }
        }
    }
}

// MARK: - Reusable Input Field
struct CustomInputField: View {
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
