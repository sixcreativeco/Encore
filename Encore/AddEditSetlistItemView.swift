import SwiftUI
import Combine

struct AddEditSetlistItemView: View {
    @Binding var item: SetlistItemModel
    let onSave: (SetlistItemModel) -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) var dismiss

    @State private var isSong: Bool
    
    private let keys = ["", "C", "C# / Db", "D", "D# / Eb", "E", "F", "F# / Gb", "G", "G# / Ab", "A", "A# / Bb", "B"]
    private let tonalities = ["Major", "Minor"]

    init(item: Binding<SetlistItemModel>, onSave: @escaping (SetlistItemModel) -> Void, onDelete: @escaping () -> Void) {
        self._item = item
        self.onSave = onSave
        self.onDelete = onDelete
        
        if case .song = item.wrappedValue.itemType {
            _isSong = State(initialValue: true)
        } else {
            _isSong = State(initialValue: false)
        }
    }

    var body: some View {
        // The root is a simple VStack. NO SCROLLVIEW.
        VStack(alignment: .leading, spacing: 20) {
            header
            
            CustomSegmentedPicker(selected: $isSong, options: [true, false], labels: ["Song", "Marker"])
            
            Divider()

            // The forms are placed directly in the VStack.
            if isSong {
                songForm
            } else {
                markerForm
            }
            
            // A Spacer pushes the buttons to the bottom of the fixed-size frame.
            Spacer()
            
            footerButtons
        }
        .padding(32)
        // FIX: A large, fixed frame is applied to the entire view.
        // This forces the window to be big enough to show everything.
        // You can adjust the height value if needed.
        .frame(width: 650, height: 900)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: isSong) { _, newIsSong in
            if newIsSong {
                if case .marker(let details) = item.itemType {
                    item.itemType = .song(SongDetails(name: details.description))
                }
            } else {
                if case .song(let details) = item.itemType {
                    item.itemType = .marker(MarkerDetails(description: details.name))
                }
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
            StyledInputField(placeholder: "Song Name*", text: songBinding(for: \.name))
            
            VStack(alignment: .leading) {
                Text("Musical Details").font(.headline)
                HStack(spacing: 16) {
                    StyledInputField(placeholder: "BPM", text: optionalIntBinding(for: songBinding(for: \.bpm))).frame(width: 100)
                    StyledDropdown(label: "Key", selection: optionalStringBinding(for: songBinding(for: \.key)), options: keys)
                    CustomSegmentedPicker(selected: optionalStringBinding(for: songBinding(for: \.tonality)), options: tonalities)
                }
            }
            
            VStack(alignment: .leading) {
                Text("Official Notes (for Export)").font(.headline).padding(.top, 10)
                CustomTextEditor(placeholder: "Performance Notes", text: optionalStringBinding(for: songBinding(for: \.performanceNotes)))
                CustomTextEditor(placeholder: "Lighting Notes", text: optionalStringBinding(for: songBinding(for: \.lightingNotes)))
                CustomTextEditor(placeholder: "Audio Notes", text: optionalStringBinding(for: songBinding(for: \.audioNotes)))
                CustomTextEditor(placeholder: "Video Notes", text: optionalStringBinding(for: songBinding(for: \.videoNotes)))
            }
        }
    }

    @ViewBuilder
    private var markerForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Marker Details").font(.headline)
            CustomTextEditor(placeholder: "Description (e.g., Costume Change, Band Intros)", text: markerBinding(for: \.description))
        }
    }

    private var footerButtons: some View {
        HStack {
            if !itemName.isEmpty {
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
        switch item.itemType {
        case .song(let details):
            return details.name
        case .marker(let details):
            return details.description
        }
    }
    
    // --- Binding helpers are unchanged and correct ---
    private func songBinding<T>(for keyPath: WritableKeyPath<SongDetails, T>) -> Binding<T> {
        Binding( get: {
            guard case .song(let details) = self.item.itemType else { fatalError() }
            return details[keyPath: keyPath]
        }, set: { newValue in
            guard case .song(var details) = self.item.itemType else { return }
            details[keyPath: keyPath] = newValue
            self.item.itemType = .song(details)
        })
    }

    private func markerBinding<T>(for keyPath: WritableKeyPath<MarkerDetails, T>) -> Binding<T> {
        Binding( get: {
            guard case .marker(let details) = self.item.itemType else { fatalError() }
            return details[keyPath: keyPath]
        }, set: { newValue in
            guard case .marker(var details) = self.item.itemType else { return }
            details[keyPath: keyPath] = newValue
            self.item.itemType = .marker(details)
        })
    }
    
    private func optionalStringBinding(for binding: Binding<String?>) -> Binding<String> {
        Binding<String>( get: { binding.wrappedValue ?? "" }, set: { binding.wrappedValue = $0.isEmpty ? nil : $0 } )
    }
    
    private func optionalIntBinding(for binding: Binding<Int?>) -> Binding<String> {
        Binding<String>( get: { binding.wrappedValue != nil ? String(binding.wrappedValue!) : "" }, set: { binding.wrappedValue = Int($0) } )
    }
}
