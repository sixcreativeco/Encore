import SwiftUI

struct InputListView: View {
    @StateObject private var viewModel: InputListViewModel
    
    @State private var showingItemSheet = false
    @State private var itemToEdit: InputListItem?

    init(tour: Tour) {
        _viewModel = StateObject(wrappedValue: InputListViewModel(tour: tour))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Input List").font(.headline)
                Spacer()
                Button(action: {
                    itemToEdit = nil
                    showingItemSheet = true
                }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.inputItems.isEmpty {
                Text("No inputs have been added to the list.")
                    .foregroundColor(.secondary)
            } else {
                List {
                    Section {
                        ForEach(viewModel.inputItems) { item in
                            inputItemRow(item)
                                .onTapGesture {
                                    itemToEdit = item
                                    showingItemSheet = true
                                }
                        }
                        .onDelete(perform: viewModel.deleteItem)
                    } header: {
                        HStack {
                            Text("Ch").frame(width: 40, alignment: .leading)
                            Text("Input").frame(maxWidth: .infinity, alignment: .leading)
                            Text("Mic / DI").frame(maxWidth: .infinity, alignment: .leading)
                            Text("Stand").frame(width: 100, alignment: .leading)
                        }
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    }
                }
                .listStyle(.plain)
            }
        }
        .sheet(isPresented: $showingItemSheet) {
            let item = itemToEdit ?? InputListItem(tourId: "", ownerId: "", channelNumber: viewModel.getNextChannelNumber(), inputName: "")
            InputItemEditView(item: item) { savedItem in
                viewModel.saveItem(savedItem)
                showingItemSheet = false
                itemToEdit = nil
            }
        }
    }
    
    private func inputItemRow(_ item: InputListItem) -> some View {
        HStack {
            Text("\(item.channelNumber)")
                .fontWeight(.bold)
                .frame(width: 40, alignment: .leading)
            Text(item.inputName)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(item.microphoneOrDI ?? "-")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(item.standType ?? "-")
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
        }
    }
}

// MARK: - Add/Edit Sheet View

fileprivate struct InputItemEditView: View {
    @State var item: InputListItem
    var onSave: (InputListItem) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    private var isFormValid: Bool {
        !item.inputName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(item.id == nil ? "Add Input" : "Edit Input")
                .font(.largeTitle.bold())
            
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Channel").font(.subheadline).foregroundColor(.secondary)
                    Stepper("\(item.channelNumber)", value: $item.channelNumber, in: 1...128)
                }
                
                VStack(alignment: .leading) {
                    Text("Input Name").font(.subheadline).foregroundColor(.secondary)
                    StyledInputField(placeholder: "e.g., Lead Vocal", text: $item.inputName)
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Microphone / DI").font(.subheadline).foregroundColor(.secondary)
                    StyledInputField(placeholder: "e.g., Shure SM58", text: Binding(
                        get: { item.microphoneOrDI ?? "" },
                        set: { item.microphoneOrDI = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                VStack(alignment: .leading) {
                    Text("Stand Type").font(.subheadline).foregroundColor(.secondary)
                    StyledInputField(placeholder: "e.g., Tall Boom", text: Binding(
                        get: { item.standType ?? "" },
                        set: { item.standType = $0.isEmpty ? nil : $0 }
                    ))
                }
            }
            
            VStack(alignment: .leading) {
                Text("Notes").font(.subheadline).foregroundColor(.secondary)
                CustomTextEditor(placeholder: "(Optional)", text: Binding(
                    get: { item.notes ?? "" },
                    set: { item.notes = $0.isEmpty ? nil : $0 }
                ))
            }
            
            Spacer()
            
            Button(action: { onSave(item) }) {
                Text("Save Input")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(!isFormValid)
        }
        .padding(30)
        .frame(minWidth: 550, minHeight: 550)
    }
}
