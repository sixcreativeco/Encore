import SwiftUI
import FirebaseFirestore

struct SetlistView: View {
    @EnvironmentObject var appState: AppState
    let tourID: String
    let showID: String
    let ownerUserID: String
    
    @State private var setlistItems: [SetlistItem] = []
    @State private var listener: ListenerRegistration?
    
    @State private var itemToEdit: SetlistItem?
    @State private var itemForNotes: SetlistItem?
    
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            
            if setlistItems.isEmpty {
                placeholderView
            } else {
                list
            }
        }
        .onAppear(perform: setupListener)
        .onDisappear { listener?.remove() }
        .sheet(item: $itemToEdit) { item in
            // This binding logic finds the item in our local array to edit.
            // If it's a new item, it creates a temporary binding.
            let binding = Binding<SetlistItem>(
                get: {
                    if let index = setlistItems.firstIndex(where: { $0.id == item.id }) {
                        return setlistItems[index]
                    }
                    return item // For a new item not yet in the array
                },
                set: { updatedItem in
                    if let index = setlistItems.firstIndex(where: { $0.id == updatedItem.id }) {
                        setlistItems[index] = updatedItem
                    } else {
                        itemToEdit = updatedItem // Update the temporary state for a new item
                    }
                }
            )
            
            AddEditSetlistItemView(
                item: binding,
                onSave: { finalItem in
                    // --- FIX IS HERE ---
                    // First, save to the database.
                    SetlistService.shared.saveItem(finalItem)
                    
                    // Second, update our local array immediately for an instant UI refresh.
                    if let index = setlistItems.firstIndex(where: { $0.id == finalItem.id }) {
                        // If it's an existing item, update it.
                        setlistItems[index] = finalItem
                    } else {
                        // If it's a new item, append it.
                        setlistItems.append(finalItem)
                    }
                },
                onDelete: {
                    if let index = setlistItems.firstIndex(where: { $0.id == item.id }) {
                        deleteItem(at: index)
                    }
                }
            )
        }
        .sheet(item: $itemForNotes) { item in
            SetlistNotesView(item: item)
                .environmentObject(appState)
        }
        .animation(.default, value: setlistItems)
    }
    
    private var header: some View {
        HStack {
            Text("Setlist").font(.headline)
            Spacer()
            
            Button(isEditing ? "Done" : "Reorder") {
                isEditing.toggle()
            }
            .buttonStyle(.plain)
            
            Button(action: addItem) {
                Image(systemName: "plus.circle.fill").font(.title2)
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)
        }
    }
    
    private var placeholderView: some View {
        Text("No Setlist Items. Add a song or marker to get started.")
            .foregroundColor(.secondary)
            .padding(40)
            .frame(maxWidth: .infinity)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
    }

    private var list: some View {
        List {
            ForEach(setlistItems) { item in
                SetlistCardView(item: item) {
                    self.itemForNotes = item
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .padding(.vertical, 2)
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button { itemToEdit = item } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) { deleteItem(at: item) } label: { Label("Delete", systemImage: "trash") }
                }
            }
            .onMove(perform: isEditing ? moveItems : nil)
        }
        .listStyle(.plain)
        .background(Color.clear)
    }

    // MARK: - Data Functions
    
    private func setupListener() {
        listener?.remove()
        listener = SetlistService.shared.addListener(forShow: showID) { fetchedItems in
            // The listener will keep our data in sync with the database.
            self.setlistItems = fetchedItems
        }
    }
    
    private func addItem() {
        let newItem = SetlistItem(
            id: UUID().uuidString,
            showId: self.showID,
            tourId: self.tourID,
            order: setlistItems.count,
            type: .song,
            songTitle: ""
        )
        self.itemToEdit = newItem
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        var revisedItems = setlistItems
        revisedItems.move(fromOffsets: source, toOffset: destination)
        
        for (index, item) in revisedItems.enumerated() {
            revisedItems[index].order = index
        }
        
        SetlistService.shared.updateOrder(for: revisedItems)
    }
    
    private func deleteItem(at item: SetlistItem) {
        guard let itemID = item.id else { return }
        SetlistService.shared.deleteItem(itemID)
    }
    
    private func deleteItem(at index: Int) {
        let item = setlistItems[index]
        deleteItem(at: item)
    }
}
