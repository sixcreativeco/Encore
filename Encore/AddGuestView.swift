import SwiftUI
import FirebaseFirestore

struct AddGuestView: View {
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

            VStack(alignment: .leading, spacing: 16) {
                Text("Guest").font(.headline)

                HStack(spacing: 12) {
                    CustomInputField(placeholder: "Name", text: $name)
                        .frame(width: 295, height: 38)

                    Text("+")
                        .font(.title2.bold())

                    CustomInputField(placeholder: "0", text: $additionalGuests)
                        .frame(width: 80, height: 38)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Note").font(.headline)
                    CustomInputField(placeholder: "Optional note", text: $note)
                        .frame(height: 38)
                }
            }

            Button(action: { saveGuest() }) {
                Text("Save")
                    .font(.headline)
                    .frame(width: 120, height: 44)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)

            Spacer().frame(height: 20)
        }
        .padding()
        .frame(width: windowWidth)
        .frame(minHeight: 300)
    }

    private func saveGuest() {
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "name": name,
            "additionalGuests": additionalGuests,
            "note": note
        ]

        db.collection("users").document(userID).collection("tours").document(tourID)
            .collection("shows").document(showID).collection("guestlist").addDocument(data: data) { _ in
                dismiss()
                onSave()
            }
    }
}

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
                .padding(.vertical, 6)
                .background(Color.clear)
                .cornerRadius(8)
                .textFieldStyle(PlainTextFieldStyle())
        }
    }

    private var inputBackgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 50/255, green: 50/255, blue: 50/255)
            : Color(red: 240/255, green: 240/255, blue: 240/255)
    }
}
