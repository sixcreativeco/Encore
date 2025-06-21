import SwiftUI
import Combine

struct AddEditSetlistItemView: View {
    @Binding var item: SetlistItem
    let onSave: (SetlistItem) -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) var dismiss

    @State private var isSong: Bool
    
    private let keys = ["", "C", "C# / Db", "D", "D# / Eb", "E", "F", "F# / Gb", "G", "G# / Ab", "A", "A# / Bb", "B"]
    private let tonalities = ["Major", "Minor"]

    // This initializer is now much simpler.
    init(item: Binding<SetlistItem>, onSave: @escaping (SetlistItem) -> Void, onDelete: @escaping () -> Void) {
        self._item = item
        self.onSave = onSave
        self.onDelete = onDelete
        self._isSong = State(initialValue: item.wrappedValue.type == .song)
    }

    var body: some View {
        // We will use the simple, non-scrolling VStack with a fixed frame that we know works.
        VStack(alignment: .leading, spacing: 20) {
            header
            
            CustomSegmentedPicker(selected: $isSong, options: [true, false], labels: ["Song", "Marker"])
            
            Divider()

            // The form is now in a ScrollView to ensure all fields are accessible
            // even if the window is somehow smaller than the content.
            ScrollView {
                if isSong {
                    songForm
                } else {
                    markerForm
                }
            }
            
            Spacer()
            
            footerButtons
        }
        .padding(32)
        .frame(width: 650, height: 900) // Using the stable, fixed-size window approach
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: isSong) { _, newIsSong in
            // This logic is now much simpler. We just change the type and move the title.
            if newIsSong {
                item.type = .song
                item.songTitle = item.markerDescription ?? ""
                item.markerDescription = nil
            } else {
                item.type = .marker
                item.markerDescription = item.songTitle ?? ""
                // Clear out song-specific fields
                item.songTitle = nil
                item.bpm = nil
                item.key = nil
                item.tonality = nil
            }
        }
    }
    
    private var header: some View {
        HStack {
            Text(itemName.isEmpty ? "Add Setlist Item" : "Edit Setlist Item")
                .font(.largeTitle.bold())
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray)
            }.buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private var songForm: some View {
        VStack(alignment: .leading, spacing: 18) {
            // We now bind directly to the item's properties using our simple helpers.
            StyledInputField(placeholder: "Song Name*", text: optionalStringBinding(for: $item.songTitle))
            
            VStack(alignment: .leading) {
                Text("Musical Details").font(.headline)
                HStack(spacing: 16) {
                    StyledInputField(placeholder: "BPM", text: optionalIntBinding(for: $item.bpm)).frame(width: 100)
                    StyledDropdown(label: "Key", selection: optionalStringBinding(for: $item.key), options: keys)
                    CustomSegmentedPicker(selected: optionalStringBinding(for: $item.tonality), options: tonalities)
                }
            }
            
            VStack(alignment: .leading) {
                Text("Official Notes (for Export)").font(.headline).padding(.top, 10)
                CustomTextEditor(placeholder: "Performance Notes", text: optionalStringBinding(for: $item.performanceNotes))
                CustomTextEditor(placeholder: "Lighting Notes", text: optionalStringBinding(for: $item.lightingNotes))
                CustomTextEditor(placeholder: "Audio Notes", text: optionalStringBinding(for: $item.audioNotes))
                CustomTextEditor(placeholder: "Video Notes", text: optionalStringBinding(for: $item.videoNotes))
            }
        }
    }

    @ViewBuilder
    private var markerForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Marker Details").font(.headline)
            CustomTextEditor(placeholder: "Description (e.g., Costume Change, Band Intros)", text: optionalStringBinding(for: $item.markerDescription))
        }
    }

    private var footerButtons: some View {
        HStack {
            if item.id != nil && !item.id!.isEmpty {
                Button(action: { onDelete(); dismiss() }) {
                    Label("Delete Item", systemImage: "trash")
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }.buttonStyle(.plain)
            } else {
                Spacer()
            }
            
            Button(action: { onSave(item); dismiss() }) {
                Label("Save Changes", systemImage: "checkmark.circle.fill")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(itemName.isEmpty)
        }
    }

    private var itemName: String {
        switch item.type {
        case .song:
            return item.songTitle ?? ""
        case .marker:
            return item.markerDescription ?? ""
        }
    }

    // --- Binding helpers for optional values ---
    // These are now much simpler because we don't need complex KeyPaths.
    
    private func optionalStringBinding(for binding: Binding<String?>) -> Binding<String> {
        Binding<String>(
            get: { binding.wrappedValue ?? "" },
            set: { binding.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
    
    private func optionalIntBinding(for binding: Binding<Int?>) -> Binding<String> {
        Binding<String>(
            get: {
                if let value = binding.wrappedValue {
                    return String(value)
                }
                return ""
            },
            set: {
                binding.wrappedValue = Int($0)
            }
        )
    }
}
