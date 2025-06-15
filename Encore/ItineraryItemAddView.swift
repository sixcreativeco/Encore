import SwiftUI
import FirebaseFirestore

struct ItineraryItemAddView: View {
    var tourID: String
    var userID: String
    var presetDate: Date
    var onSave: () -> Void

    @Environment(\.dismiss) var dismiss

    @State private var type: ItineraryItemType = .custom
    @State private var title = ""
    @State private var time: Date = Date()
    @State private var note = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Add Itinerary Item").font(.largeTitle.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .medium))
                        .padding(10)
                }
                .buttonStyle(.plain)
            }

            Picker("Type", selection: $type) {
                ForEach(ItineraryItemType.allCases, id: \.self) { itemType in
                    Text(itemType.displayName).tag(itemType)
                }
            }
            .pickerStyle(.menu)

            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)

            DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)

            TextField("Note", text: $note)
                .textFieldStyle(.roundedBorder)

            Button("Save Item") {
                saveItem()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)

            Spacer()
        }
        .padding()
        .frame(minWidth: 400)
        .onAppear {
            initializeTime()
        }
    }

    private func initializeTime() {
        let calendar = Calendar.current
        let now = Date()
        let merged = calendar.date(
            bySettingHour: calendar.component(.hour, from: now),
            minute: calendar.component(.minute, from: now),
            second: 0,
            of: presetDate
        ) ?? presetDate

        self.time = merged
    }

    private func saveItem() {
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "type": type.rawValue,
            "title": title,
            "time": Timestamp(date: time),
            "note": note
        ]

        db.collection("users").document(userID).collection("tours").document(tourID).collection("itinerary").addDocument(data: data) { error in
            if let error = error {
                print("Error adding itinerary item: \(error.localizedDescription)")
            } else {
                onSave()
                dismiss()
            }
        }
    }
}
