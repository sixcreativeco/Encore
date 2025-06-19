import SwiftUI
import FirebaseFirestore

struct SetlistView: View {
    // IDs passed from the parent view (ShowDetailView)
    let tourID: String
    let showID: String
    let ownerUserID: String
    
    // State
    @State private var setlistItems: [SetlistItemModel] = []
    @State private var listener: ListenerRegistration?
    @State private var showAddItemSheet = false // FIXED: This variable was missing or misspelled.
    @State private var itemToEdit: SetlistItemModel?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            
            if setlistItems.isEmpty {
                placeholderView
            } else {
                list
            }
        }
        .onAppear(perform: setupListener)
        .onDisappear { listener?.remove() }
        .sheet(isPresented: $showAddItemSheet) { // FIXED: Now references the declared state variable.
            AddEditSetlistItemView(order: setlistItems.count) { newItem in
                SetlistService.shared.addItem(newItem, toShow: showID, inTour: tourID, byUser: ownerUserID) { error in
                    if let error = error { print("Error adding item: \(error.localizedDescription)") }
                }
            }
        }
        .sheet(item: $itemToEdit) { item in
            AddEditSetlistItemView(item: item) { updatedItem in
                SetlistService.shared.updateItem(updatedItem, inShow: showID, inTour: tourID, byUser: ownerUserID) { error in
                    if let error = error { print("Error updating item: \(error.localizedDescription)") }
                }
            }
        }
    }
    
    private var header: some View {
        HStack {
            Text("Setlist").font(.headline)
            Spacer()
            Button(action: { showAddItemSheet = true }) { // FIXED: Now references the declared state variable.
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var placeholderView: some View {
        VStack {
            Spacer()
            Text("No Setlist Items")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Add a song or note to get started.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    private var list: some View {
        // List supports drag-and-drop reordering natively.
        List {
            ForEach(setlistItems) { item in
                SetlistCardView(item: item)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 6)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button { itemToEdit = item } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { deleteItem(item: item) } label: { Label("Delete", systemImage: "trash") }
                    }
            }
            .onMove(perform: moveItems)
        }
        .listStyle(.plain)
        .background(Color.clear)
    }

    /// Sets up the Firestore listener to automatically sync changes.
    private func setupListener() {
        listener?.remove() // Ensure no duplicate listeners
        listener = SetlistService.shared.addListener(forShow: showID, inTour: tourID, byUser: ownerUserID) { items in
            self.setlistItems = items
        }
    }
    
    /// Handles reordering of items from the List's onMove modifier.
    private func moveItems(from source: IndexSet, to destination: Int) {
        var revisedItems = setlistItems
        revisedItems.move(fromOffsets: source, toOffset: destination)
        
        // Update the `order` property on each item based on its new index.
        for (index, item) in revisedItems.enumerated() {
            revisedItems[index].order = index
        }
        
        self.setlistItems = revisedItems
        
        // Save the new order to Firestore.
        SetlistService.shared.updateOrder(for: revisedItems, inShow: showID, inTour: tourID, byUser: ownerUserID) { error in
            if let error = error {
                print("Error updating setlist order: \(error.localizedDescription)")
            }
        }
    }
    
    /// Deletes a single item from the setlist.
    private func deleteItem(item: SetlistItemModel) {
        SetlistService.shared.deleteItem(itemID: item.id, fromShow: showID, inTour: tourID, byUser: ownerUserID) { error in
            if let error = error {
                print("Error deleting item: \(error.localizedDescription)")
            }
        }
    }
}
