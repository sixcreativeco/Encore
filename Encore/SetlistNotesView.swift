import SwiftUI
import FirebaseFirestore

struct SetlistNotesView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    let tourID: String
    let showID: String
    let ownerUserID: String
    let songItem: SetlistItemModel

    @State private var notes: [PersonalNoteModel] = []
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
    
    private func noteRow(_ note: PersonalNoteModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.content)
            
            let dateString = note.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "pending"
            Text("by \(note.authorCrewMemberID.prefix(8)) on \(dateString)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                if case .song(let details) = songItem.itemType {
                    Text(details.name)
                        .font(.largeTitle.bold())
                }
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
    
    private func setupListener() {
        // FIXED: 'songItem.id' is not optional, no unwrap needed.
        let itemID = songItem.id
        listener = SetlistService.shared.addNotesListener(for: itemID, inShow: showID, inTour: tourID, byUser: ownerUserID) { fetchedNotes in
            self.notes = fetchedNotes
        }
    }
    
    private func addNote() {
        // FIXED: 'songItem.id' is not optional, no unwrap needed.
        guard let currentUserID = appState.userID else { return }
        let itemID = songItem.id
        let note = PersonalNoteModel(content: newNoteContent, authorCrewMemberID: currentUserID)
        try? SetlistService.shared.saveNote(note, for: itemID, inShow: showID, inTour: tourID, byUser: ownerUserID)
        newNoteContent = ""
    }
    
    private func deleteNote(at offsets: IndexSet) {
        let notesToDelete = offsets.map { notes[$0] }
        let itemID = songItem.id
        for note in notesToDelete {
            // FIXED: 'note.id' is not optional, no unwrap needed.
            SetlistService.shared.deleteNote(note.id, from: itemID, inShow: showID, inTour: tourID, byUser: ownerUserID)
        }
    }
}
