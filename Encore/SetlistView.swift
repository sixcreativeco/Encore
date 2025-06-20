import SwiftUI
import FirebaseFirestore

struct SetlistView: View {
    @EnvironmentObject var appState: AppState
    let tourID: String
    let showID: String
    let ownerUserID: String
    
    @State private var setlistItems: [SetlistItemModel] = []
    @State private var listener: ListenerRegistration?
    
    @State private var selectionToEdit: String?
    @State private var itemForNotes: SetlistItemModel?
    
    // FIX: Replaced the unavailable 'EditMode' with a simple boolean state for macOS.
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
        .sheet(item: $selectionToEdit) { selectionID in
            if let index = setlistItems.firstIndex(where: { $0.id == selectionID }) {
                // The NavigationView and AddEditSetlistItemView are assumed to be defined elsewhere
                // and are left as they were in your original code.
                NavigationView {
                    AddEditSetlistItemView(
                        item: $setlistItems[index],
                        onSave: { updatedItem in
                            SetlistService.shared.saveItem(updatedItem, toShow: showID, inTour: tourID, byUser: ownerUserID)
                        },
                        onDelete: {
                            deleteItem(at: index)
                        }
                    )
                    .navigationTitle("Edit Setlist Item")
                }
            }
        }
        .sheet(item: $itemForNotes) { item in
            SetlistNotesView(tourID: tourID, showID: showID, ownerUserID: ownerUserID, songItem: item)
                .environmentObject(appState)
        }
        .animation(.default, value: setlistItems)
    }
    
    private var header: some View {
        HStack {
            Text("Setlist").font(.headline)
            Spacer()
            
            // This button now toggles our local 'isEditing' state.
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
        // The List itself is what enables drag-and-drop reordering.
        List {
            ForEach(setlistItems) { item in
                SetlistCardView(item: item) {
                    self.itemForNotes = item
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .padding(.vertical, 2)
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button { selectionToEdit = item.id } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) { deleteItem(at: item) } label: { Label("Delete", systemImage: "trash") }
                }
            }
            // The .onMove modifier is only enabled when our 'isEditing' state is true.
            .onMove(perform: isEditing ? moveItems : nil)
        }
        .listStyle(.plain)
        .background(Color.clear)
    }

    // MARK: - Data Functions
    
    private func setupListener() {
        listener?.remove()
        listener = SetlistService.shared.addListener(forShow: showID, inTour: tourID, byUser: ownerUserID) { self.setlistItems = $0 }
    }
    
    private func addItem() {
        let newItem = SetlistItemModel(order: setlistItems.count, itemType: .song(SongDetails(name: "New Song")))
        SetlistService.shared.saveItem(newItem, toShow: showID, inTour: tourID, byUser: ownerUserID)
        // Set the selection to open the edit sheet for the new item
        self.selectionToEdit = newItem.id
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        var revisedItems = setlistItems
        revisedItems.move(fromOffsets: source, toOffset: destination)
        
        for (index, item) in revisedItems.enumerated() {
            revisedItems[index].order = index
        }
        
        SetlistService.shared.updateOrder(for: revisedItems, inShow: showID, inTour: tourID, byUser: ownerUserID)
    }
    
    private func deleteItem(at item: SetlistItemModel) {
        SetlistService.shared.deleteItem(item.id, fromShow: showID, inTour: tourID, byUser: ownerUserID)
    }
    
    private func deleteItem(at index: Int) {
        let item = setlistItems[index]
        deleteItem(at: item)
    }
}

// This extension is still needed for the .sheet(item: $selectionToEdit) modifier
extension String: Identifiable {
    public var id: String { self }
}
