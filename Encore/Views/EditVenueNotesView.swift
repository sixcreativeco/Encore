import SwiftUI
import FirebaseFirestore

struct EditVenueNotesView: View {
    var userID: String
    var tourID: String
    var showID: String
    var notes: String
    var onSave: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var newNotes = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Edit Venue Notes").font(.largeTitle.bold())

            TextEditor(text: $newNotes)
                .frame(height: 200)
                .border(Color.gray.opacity(0.5))

            Button("Save") {
                saveNotes()
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
        .frame(width: 400)
        .onAppear { newNotes = notes }
    }

    private func saveNotes() {
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("tours").document(tourID)
            .collection("shows").document(showID).updateData(["venueNotes": newNotes]) { _ in
                dismiss()
                onSave()
            }
    }
}
