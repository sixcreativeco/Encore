import SwiftUI
import FirebaseFirestore

struct ItineraryItemEditView: View {
    var tourID: String
    var userID: String
    var item: ItineraryItemModel
    var onSave: () -> Void

    @Environment(\.dismiss) var dismiss

    @State private var type: ItineraryItemType
    @State private var title: String
    @State private var time: Date
    @State private var note: String

    init(tourID: String, userID: String, item: ItineraryItemModel, onSave: @escaping () -> Void) {
        self.tourID = tourID
        self.userID = userID
        self.item = item
        self.onSave = onSave

        _type = State(initialValue: item.type)
        _title = State(initialValue: item.title)
        _time = State(initialValue: item.time)
        _note = State(initialValue: item.note ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Edit Itinerary Item").font(.largeTitle.bold())
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

            Button("Save Changes") {
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
    }

    private func saveItem() {
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "type": type.rawValue,
            "title": title,
            "time": Timestamp(date: time),
            "note": note
        ]

        db.collection("users").document(userID).collection("tours").document(tourID).collection("itinerary").document(item.id).setData(data) { error in
            if let error = error {
                print("Error updating itinerary item: \(error.localizedDescription)")
            } else {
                onSave()
                dismiss()
            }
        }
    }
}
