import SwiftUI
import FirebaseFirestore

struct ContentView: View {
    @State private var message = "Press the button to test Firebase."

    var body: some View {
        VStack(spacing: 20) {
            Text("Encore Admin App")
                .font(.title)
                .bold()

            Text(message)
                .foregroundColor(.gray)

            Button("Write Test Tour to Firebase") {
                let db = Firestore.firestore()
                db.collection("tours").addDocument(data: [
                    "name": "Test Tour",
                    "startDate": Date(),
                    "createdBy": "admin"
                ]) { error in
                    if let error = error {
                        message = "❌ Error: \(error.localizedDescription)"
                    } else {
                        message = "✅ Success! Test tour added."
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}
