import SwiftUI

struct GearListView: View {
    @StateObject private var viewModel: GearListViewModel
    
    @State private var showingItemSheet = false
    @State private var itemToEdit: GearItem?

    init(tour: Tour) {
        _viewModel = StateObject(wrappedValue: GearListViewModel(tour: tour))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Backline & Gear").font(.headline)
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
            } else if viewModel.documents.isEmpty {
                Text("No gear has been added for this tour.")
                    .foregroundColor(.secondary)
            } else {
                List {
                    ForEach(viewModel.groupedDocuments.keys.sorted(), id: \.self) { category in
                        Section(header: Text(category).font(.headline.bold())) {
                            ForEach(viewModel.groupedDocuments[category] ?? []) { item in
                                gearItemRow(item)
                                    .onTapGesture {
                                        itemToEdit = item
                                        showingItemSheet = true
                                    }
                            }
                            .onDelete { offsets in
                                viewModel.deleteItem(at: offsets, from: category)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .sheet(isPresented: $showingItemSheet) {
            let item = itemToEdit ?? GearItem(tourId: viewModel.tour.id ?? "", ownerId: viewModel.tour.ownerId, name: "", category: "Backline", quantity: 1)
            GearItemEditView(item: item, allCategories: viewModel.groupedDocuments.keys.sorted()) { savedItem in
                viewModel.saveItem(savedItem)
                showingItemSheet = false
                itemToEdit = nil
            }
        }
    }
    
    private func gearItemRow(_ item: GearItem) -> some View {
        HStack {
            Text("\(item.quantity)x")
                .fontWeight(.bold)
                .frame(width: 40, alignment: .leading)
            
            VStack(alignment: .leading) {
                Text(item.name)
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }
}


// MARK: - Add/Edit Sheet View

fileprivate struct GearItemEditView: View {
    @State var item: GearItem
    let allCategories: [String]
    var onSave: (GearItem) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    private var isFormValid: Bool {
        !item.name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !item.category.trimmingCharacters(in: .whitespaces).isEmpty &&
        item.quantity > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(item.id == nil ? "Add Gear Item" : "Edit Gear Item")
                .font(.largeTitle.bold())
            
            StyledInputField(placeholder: "Item Name (e.g., Fender Stratocaster)", text: $item.name)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Quantity").font(.subheadline).foregroundColor(.secondary)
                    Stepper("\(item.quantity)", value: $item.quantity, in: 1...100)
                }
                
                VStack(alignment: .leading) {
                    Text("Category").font(.subheadline).foregroundColor(.secondary)
                    Menu {
                        ForEach(allCategories, id: \.self) { category in
                            Button(category) { item.category = category }
                        }
                        Divider()
                        // This allows creating a new category on the fly
                    } label: {
                        HStack {
                            Text(item.category)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                        }
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.15))
                    .cornerRadius(10)
                }
            }
            
            CustomTextEditor(placeholder: "Notes (e.g., serial number, specific settings)", text: Binding(
                get: { item.notes ?? "" },
                set: { item.notes = $0.isEmpty ? nil : $0 }
            ))
            
            Spacer()
            
            Button(action: { onSave(item) }) {
                Text("Save Item")
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
        .frame(minWidth: 500, minHeight: 500)
    }
}
