import SwiftUI
import FirebaseFirestore

struct ItineraryItemEditView: View {
    @Binding var item: ItineraryItem
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss

    private var timeBinding: Binding<Date> {
        Binding<Date>(
            get: { self.item.timeUTC.dateValue() },
            set: { self.item.timeUTC = Timestamp(date: $0) }
        )
    }
    
    private func notesBinding(for binding: Binding<String?>) -> Binding<String> {
        Binding<String>(
            get: { binding.wrappedValue ?? "" },
            set: { binding.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Edit Itinerary Item")
                    .font(.largeTitle.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .medium))
                        .padding(10)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: ItineraryItemType(rawValue: item.type)?.iconName ?? "calendar")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 30)

                    let isShowTiming = ItineraryItemType(rawValue: item.type)?.isShowTiming ?? false
                    
                    // FIX: The incorrect 'isDisabled' parameter is removed,
                    // and the standard .disabled() modifier is applied instead.
                    StyledInputField(placeholder: "Title", text: $item.title)
                        .disabled(isShowTiming)
                }
                
                StyledTimePicker(label: "Time", time: timeBinding)
                
                CustomTextEditor(placeholder: "Notes", text: notesBinding(for: $item.notes))
            }

            Spacer()
            
            Button("Save Changes") {
                saveChanges()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 420)
    }

    private func saveChanges() {
        let db = Firestore.firestore()
        guard let itemId = item.id else {
            print("Error: Item ID is missing.")
            return
        }

        let itemRef = db.collection("itineraryItems").document(itemId)

        if let itemType = ItineraryItemType(rawValue: item.type), itemType.isShowTiming, let showId = item.showId {
            let showRef = db.collection("shows").document(showId)
            
            db.runTransaction({ (transaction, errorPointer) -> Any? in
                do {
                    try transaction.setData(from: self.item, forDocument: itemRef, merge: true)
                    
                    if let firestoreKey = itemType.firestoreShowKey {
                        transaction.updateData([firestoreKey: self.item.timeUTC], forDocument: showRef)
                    }
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }
                return nil
            }) { (object, error) in
                if let error = error {
                    print("Transaction failed: \(error)")
                } else {
                    print("Transaction successfully committed! Both ItineraryItem and Show were updated.")
                    self.onSave()
                    self.dismiss()
                }
            }
        } else {
            do {
                try itemRef.setData(from: item, merge: true)
                self.onSave()
                self.dismiss()
            } catch {
                print("Error saving regular itinerary item: \(error)")
            }
        }
    }
}
