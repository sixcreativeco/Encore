import SwiftUI

struct AddEditSetlistItemView: View {
    // Environment
    @Environment(\.dismiss) var dismiss
    
    // Properties
    let onSave: (SetlistItemModel) -> Void
    
    // State
    @State private var item: SetlistItemModel
    @State private var selectedColor: Color

    // Initializer for creating a new item
    init(order: Int, onSave: @escaping (SetlistItemModel) -> Void) {
        let newItem = SetlistItemModel(order: order, type: .song)
        self._item = State(initialValue: newItem)
        self._selectedColor = State(initialValue: .blue)
        self.onSave = onSave
    }

    // Initializer for editing an existing item
    init(item: SetlistItemModel, onSave: @escaping (SetlistItemModel) -> Void) {
        self._item = State(initialValue: item)
        self._selectedColor = State(initialValue: item.mainColor)
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            
            Picker("Item Type", selection: $item.type) {
                ForEach(SetlistItemType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            formContent
            
            Spacer()
            
            saveButton
        }
        .padding(32)
        .frame(minWidth: 450, minHeight: 400)
        .onChange(of: selectedColor) { newColor in
            // Update the hex string when the color picker changes
            item.mainColorHex = newColor.toHex()
        }
    }

    private var header: some View {
        HStack {
            Text(item.title == nil ? "Add Setlist Item" : "Edit Setlist Item")
                .font(.largeTitle.bold())
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private var formContent: some View {
        switch item.type {
        case .song:
            StyledInputField(placeholder: "Song Title", text: binding(for: $item.title))
            StyledInputField(placeholder: "Performance notes (optional)", text: binding(for: $item.notes))
        case .note:
            StyledInputField(placeholder: "Note content", text: binding(for: $item.notes))
        case .lighting:
            ColorPicker("Main Cue Color", selection: $selectedColor)
                .font(.headline)
            StyledInputField(placeholder: "Additional lighting notes", text: binding(for: $item.notes))
        case .tech:
            StyledInputField(placeholder: "Technical change notes", text: binding(for: $item.notes))
        }
    }
    
    private var saveButton: some View {
        Button(action: {
            onSave(item)
            dismiss()
        }) {
            Text("Save Item")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    /// Custom binding to handle optional strings in the model.
    private func binding(for optionalString: Binding<String?>) -> Binding<String> {
        Binding<String>(
            get: { optionalString.wrappedValue ?? "" },
            set: { optionalString.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}

// Helper extension to convert SwiftUI Color to a hex string
extension Color {
    func toHex() -> String? {
        guard let cgColor = self.cgColor else { return nil }
        let components = cgColor.components
        let r = Int((components?[0] ?? 0) * 255)
        let g = Int((components?[1] ?? 0) * 255)
        let b = Int((components?[2] ?? 0) * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
