import SwiftUI
import FirebaseFirestore

struct AddGuestView: View {
    var userID: String
    var tourID: String
    var showID: String
    var onSave: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var note = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add Guest").font(.largeTitle.bold())

            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Note (optional)", text: $note)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Save") {
                saveGuest()
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
        .frame(width: 400)
    }

    private func saveGuest() {
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "name": name,
            "note": note
        ]

        db.collection("users").document(userID).collection("tours").document(tourID)
            .collection("shows").document(showID).collection("guestlist").addDocument(data: data) { error in
                dismiss()
                onSave()
            }
    }
}
