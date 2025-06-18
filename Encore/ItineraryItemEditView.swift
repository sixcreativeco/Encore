import SwiftUI
import FirebaseFirestore

struct ItineraryItemEditView: View {
    var tourID: String
    var userID: String // This should be the ownerUserID
    var item: ItineraryItemModel
    var onSave: () -> Void

    @Environment(\.dismiss) var dismiss

    // State for general items
    @State private var type: ItineraryItemType
    @State private var title: String
    @State private var time: Date
    
    // Shared state for all items
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
                Text(item.type == .flight ? "Edit Flight Note" : "Edit Itinerary Item")
                    .font(.largeTitle.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .medium))
                        .padding(10)
                }
                .buttonStyle(.plain)
            }

            if item.type == .flight {
                Text(item.title)
                    .font(.headline)
                TextEditor(text: $note)
                    .font(.body)
                    .frame(height: 100)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))

            } else {
                // Original full editor for non-flight items
                Group {
                    Picker("Type", selection: $type) {
                        ForEach(ItineraryItemType.allCases, id: \.self) { itemType in
                            Text(itemType.displayName).tag(itemType)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    TextField("Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                    
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    
                    TextEditor(text: $note)
                        .font(.body)
                        .frame(height: 100)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                }
            }

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
        .frame(minWidth: 400, minHeight: 350)
    }

    private func saveItem() {
        // Use the new data manager to update the note everywhere for flights
        if item.type == .flight, let flightId = item.flightId {
            TourDataManager.shared.updateFlightNote(ownerUserID: userID, tourID: tourID, flightID: flightId, newNote: note) { error in
                 if let error = error {
                    print("Error updating flight note: \(error.localizedDescription)")
                } else {
                    onSave()
                    dismiss()
                }
            }
        } else {
            // Original save logic for non-flight items
            let db = Firestore.firestore()
            let data: [String: Any] = [
                "type": type.rawValue,
                "title": title,
                "time": Timestamp(date: time),
                "note": note
            ]

            // This path assumes a top-level itinerary collection that holds all items.
            // If items are nested under a day document, this path needs adjustment.
            db.collection("users").document(userID).collection("tours").document(tourID).collection("itinerary").document(item.id).setData(data, merge: true) { error in
                if let error = error {
                    print("Error updating itinerary item: \(error.localizedDescription)")
                } else {
                    onSave()
                    dismiss()
                }
            }
        }
    }
}
