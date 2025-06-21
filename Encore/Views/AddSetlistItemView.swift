import SwiftUI

// This is a new, dedicated view for ADDING an item.
struct AddSetlistItemView: View {
    let tourID: String
    let showID: String
    let initialOrder: Int
    let onSave: (SetlistItem) -> Void
    @Environment(\.dismiss) var dismiss

    // The view manages its own state for the new item being created.
    @State private var newItem: SetlistItem

    init(tourID: String, showID: String, order: Int, onSave: @escaping (SetlistItem) -> Void) {
        self.tourID = tourID
        self.showID = showID
        self.initialOrder = order
        self.onSave = onSave
        
        // Create a new, blank item when the view appears.
        _newItem = State(initialValue: SetlistItem(
            id: UUID().uuidString, // Generate a client-side ID
            showId: showID,
            tourId: tourID,
            order: order,
            type: .song,
            songTitle: "New Song"
        ))
    }

    var body: some View {
        // We pass the binding to our local state item to the edit view.
        // This reuses the form UI, but for a new item.
        AddEditSetlistItemView(
            item: $newItem,
            onSave: { finalItem in
                // When "Save" is pressed in the form, we call the onSave closure
                // from the parent view (SetlistView) to save it to Firestore.
                onSave(finalItem)
            },
            onDelete: {
                // A new item can't be deleted, so this closure is empty.
            }
        )
    }
}
