import SwiftUI
import FirebaseFirestore

struct SetlistNotesView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    // This now accepts our new, flat SetlistItem model.
    let item: SetlistItem

    // State now uses the new PersonalNote model.
    @State private var notes: [PersonalNote] = []
    @State private var newNoteContent: String = ""
    @State private var listener: ListenerRegistration?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            
            List {
                ForEach(notes) { note in
                    noteRow(note)
                        .padding(.vertical, 4)
                }
                .onDelete(perform: deleteNote)
            }
            .listStyle(.plain)
            
            editor
        }
        .onAppear(perform: setupListener)
        .onDisappear { listener?.remove() }
        .frame(minWidth: 450, idealWidth: 550, minHeight: 400, maxHeight: 700)
    }
    
    private func noteRow(_ note: PersonalNote) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.content)
            
            // The createdAt timestamp is now handled by the @ServerTimestamp wrapper.
            let dateString = note.createdAt?.dateValue().formatted(date: .abbreviated, time: .shortened) ?? "pending"
            Text("by \(note.authorCrewMemberId.prefix(8)) on \(dateString)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                // We now get the name directly from the flat item properties.
                Text(itemName)
                    .font(.largeTitle.bold())
                
                Text("Personal Notes & Comments")
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray)
            }.buttonStyle(.plain)
        }
        .padding()
    }
    
    private var editor: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .top, spacing: 16) {
                TextField("Add a new note...", text: $newNoteContent, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                
                Button("Add", action: addNote)
                    .disabled(newNoteContent.isEmpty)
            }
            .padding()
        }
    }
    
    // Helper to get the display name for the header.
    private var itemName: String {
        switch item.type {
        case .song:
            return item.songTitle ?? "Untitled Song"
        case .marker:
            return item.markerDescription ?? "Untitled Marker"
        }
    }
    
    // MARK: - Data Functions (Refactored)

    private func setupListener() {
        guard let itemID = item.id else { return }
        listener?.remove()
        // The new service call is much simpler.
        listener = SetlistService.shared.addNotesListener(for: itemID) { fetchedNotes in
            self.notes = fetchedNotes
        }
    }
    
    private func addNote() {
        guard let currentUserID = appState.userID, let setlistItemID = item.id else { return }
        
        // Create an instance of our new PersonalNote model, ensuring it has all the necessary IDs.
        let note = PersonalNote(
            setlistItemId: setlistItemID,
            showId: item.showId,
            tourId: item.tourId,
            content: newNoteContent,
            authorCrewMemberId: currentUserID
        )
        
        // The new service call is much simpler.
        SetlistService.shared.saveNote(note)
        newNoteContent = ""
    }
    
    private func deleteNote(at offsets: IndexSet) {
        let notesToDelete = offsets.map { notes[$0] }
        for note in notesToDelete {
            guard let noteID = note.id else { continue }
            // The new service call is much simpler.
            SetlistService.shared.deleteNote(noteID)
        }
    }
}
