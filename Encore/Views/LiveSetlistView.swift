import SwiftUI
import UniformTypeIdentifiers

struct LiveSetlistView: View {
    @StateObject private var viewModel: LiveSetlistViewModel
    @Environment(\.dismiss) var dismiss

    @State private var editingText: String = ""
    @FocusState private var isEditingFocused: Bool
    
    @State private var isDragging = false

    // Represents a single row in the UI, which can contain one or more items.
    struct SetlistUIRow: Identifiable {
        var id: String { items.first?.id ?? UUID().uuidString }
        var items: [SetlistItem]
    }

    // Transforms the flat data from the view model into a grid-like structure for the UI.
    private var setlistRows: [SetlistUIRow] {
        var rows: [SetlistUIRow] = []
        guard !viewModel.setlistItems.isEmpty else { return rows }
        
        for item in viewModel.setlistItems {
            if item.type == .song || item.type == .a_break {
                rows.append(SetlistUIRow(items: [item]))
                continue
            }
            
            if let lastRow = rows.last, let firstItem = lastRow.items.first,
               firstItem.type != .song && firstItem.type != .a_break && lastRow.items.count < 3 {
                rows[rows.count - 1].items.append(item)
            } else {
                rows.append(SetlistUIRow(items: [item]))
            }
        }
        return rows
    }

    init(tour: Tour, show: Show) {
        _viewModel = StateObject(wrappedValue: LiveSetlistViewModel(tour: tour, show: show))
    }
    
    private var formattedTime: String {
        let hours = Int(viewModel.elapsedTime) / 3600
        let minutes = (Int(viewModel.elapsedTime) % 3600) / 60
        let seconds = Int(viewModel.elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    var body: some View {
        ZStack {
            mainContent.background(Color.clear)
            floatingIcons
        }
        .background(Color(red: 23/255, green: 24/255, blue: 28/255))
        .foregroundColor(.white)
        .frame(minWidth: 1000, idealWidth: 1200, maxWidth: .infinity, minHeight: 700, idealHeight: 800, maxHeight: .infinity)
        .onChange(of: viewModel.editingItemID) { _, newItemID in
            if let newItemID = newItemID, let item = viewModel.setlistItems.first(where: { $0.id == newItemID }) {
                editingText = item.songTitle ?? item.markerDescription ?? ""
                isEditingFocused = true
            }
        }
        .onDrop(of: [UTType.text], isTargeted: nil) { providers in
            isDragging = false
            return true
        }
    }

    // MARK: - Subviews

    private var floatingIcons: some View {
        VStack {
            Spacer()
            VStack(spacing: 28) {
                sidebarIcon(type: .song, iconName: "music.note")
                sidebarIcon(type: .note, iconName: "note.text")
                sidebarIcon(type: .lightingNote, iconName: "lightbulb.fill")
                sidebarIcon(type: .soundNote, iconName: "waveform")
                sidebarIcon(type: .pageBreak, iconName: "ruler.fill")
                Spacer().frame(height: 20)
                Button(action: viewModel.deleteSelectedItems) {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundColor(viewModel.selection.isEmpty ? .white.opacity(0.25) : .red.opacity(0.8))
                }.buttonStyle(.plain).disabled(viewModel.selection.isEmpty)
            }
            .padding(24).background(.ultraThinMaterial).cornerRadius(20).shadow(radius: 10)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }
    
    private func sidebarIcon(type: LiveSetlistViewModel.DraggableItem, iconName: String) -> some View {
        Image(systemName: iconName)
            .font(.title2).foregroundColor(.white.opacity(0.8)).frame(width: 44, height: 44)
            .onDrag {
                self.isDragging = true
                return NSItemProvider(object: type.rawValue as NSString)
            }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView.padding(.horizontal, 40)
            
            ScrollView {
                VStack(spacing: 0) {
                    DropZoneView(insertionIndex: 0, isDragging: $isDragging, viewModel: viewModel)
                    
                    ForEach(setlistRows) { row in
                        let insertionIndex = viewModel.setlistItems.firstIndex(where: { $0.id == row.items.first?.id }) ?? 0
                        rowView(for: row, baseIndex: insertionIndex)
                        DropZoneView(insertionIndex: insertionIndex + row.items.count, isDragging: $isDragging, viewModel: viewModel)
                    }
                }
                .padding(.horizontal, 40)
            }
        }
        .padding(.top, 40)
    }

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Button(action: { dismiss() }) {
                    HStack { Image(systemName: "chevron.left"); Text("Back to Show") }
                }.buttonStyle(.plain).foregroundColor(.gray).padding(.bottom, 12)
                Text(viewModel.tour.artist).font(.system(size: 60, weight: .bold))
                HStack(spacing: 12) {
                    Text(viewModel.show.venueName)
                    Text(viewModel.show.date.dateValue().formatted(.dateTime.day().month().year())).foregroundColor(.white.opacity(0.6))
                }.font(.system(size: 18, weight: .medium))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 16) {
                timecodeView
                tabsView
            }
        }.padding(.bottom, 20)
    }
    
    private var timecodeView: some View {
        HStack(spacing: 12) {
            HStack {
                Circle().fill(Color.green).frame(width: 8, height: 8)
                Text("Current Song").font(.caption).foregroundColor(.white.opacity(0.7))
                Text(viewModel.currentSongTitle).font(.caption.bold())
            }
            Text(formattedTime).font(.system(size: 32, weight: .medium).monospacedDigit())
            Button(action: viewModel.toggleTimer) {
                Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill").font(.title2).frame(width: 32, height: 32).background(Color.white.opacity(0.2)).clipShape(Circle())
            }.buttonStyle(.plain)
            Button(action: viewModel.stopTimer) {
                 Image(systemName: "stop.fill").font(.title2)
            }.buttonStyle(.plain).opacity(viewModel.elapsedTime > 0 ? 1 : 0)
        }.padding(.horizontal, 16).padding(.vertical, 8).background(Color.black.opacity(0.3)).cornerRadius(100)
    }
    
    private var tabsView: some View {
        HStack(spacing: 24) {
            tabButton(for: .main); tabButton(for: .artist); tabButton(for: .lighting); tabButton(for: .sound)
        }
    }
    
    private func tabButton(for tab: LiveSetlistViewModel.SetlistTab) -> some View {
        Button(action: { viewModel.selectedTab = tab }) {
            Text(tab.rawValue).font(.system(size: 16, weight: .medium)).foregroundColor(viewModel.selectedTab == tab ? .white : .white.opacity(0.5))
        }.buttonStyle(.plain)
    }
    
    // MARK: - Row and Item Views
    
    @ViewBuilder
    private func rowView(for row: SetlistUIRow, baseIndex: Int) -> some View {
        HStack(spacing: 16) {
            if row.items.first?.type != .song && row.items.first?.type != .a_break {
                DropZoneView(insertionIndex: baseIndex, isHorizontal: true, isDragging: $isDragging, viewModel: viewModel)
            }
            
            ForEach(Array(row.items.enumerated()), id: \.element.id) { idx, item in
                if let index = viewModel.setlistItems.firstIndex(where: { $0.id == item.id }) {
                    setlistItemView(for: $viewModel.setlistItems[index])
                }
                
                if row.items.first?.type != .song && row.items.first?.type != .a_break {
                    DropZoneView(insertionIndex: baseIndex + idx + 1, isHorizontal: true, isDragging: $isDragging, viewModel: viewModel)
                }
            }
        }
        .padding(.leading, 100)
    }

    @ViewBuilder
    private func setlistItemView(for itemBinding: Binding<SetlistItem>) -> some View {
        let item = itemBinding.wrappedValue
        Group {
            if viewModel.editingItemID == item.id {
                editableTextField(for: itemBinding)
            } else {
                switch item.type {
                case .song:
                    Text(item.songTitle ?? "SONG TITLE").font(.system(size: 48, weight: .bold))
                case .marker:
                    Text(item.markerDescription ?? "Note").font(.system(size: 20, weight: .regular)).foregroundColor(.white.opacity(0.6))
                case .lightingNote:
                    HStack(spacing: 12) { Image(systemName: "lightbulb.fill"); Text(item.markerDescription ?? "Lighting Cue") }.font(.system(size: 20, weight: .regular)).foregroundColor(.white.opacity(0.8))
                case .soundNote:
                    HStack(spacing: 12) { Image(systemName: "waveform"); Text(item.markerDescription ?? "Sound Cue") }.font(.system(size: 20, weight: .regular)).foregroundColor(.white.opacity(0.8))
                case .a_break:
                    HStack { VStack { Divider() }; Text(item.markerDescription ?? "Section").font(.caption).textCase(.uppercase).foregroundColor(.gray); VStack { Divider() } }
                }
            }
        }
        .padding(8)
        .frame(minHeight: 60)
        .frame(maxWidth: .infinity)
        // FIX: The background is now clear unless selected.
        .background(viewModel.selection.contains(item.id ?? "") ? Color.blue.opacity(0.4) : Color.clear)
        .cornerRadius(8)
        .onTapGesture(count: 2) {
            if viewModel.editingItemID != item.id {
                viewModel.editingItemID = item.id
            }
        }
        .onTapGesture(count: 1) {
            guard let id = item.id else { return }
            if viewModel.selection.contains(id) {
                viewModel.selection.remove(id)
            } else {
                viewModel.selection.removeAll()
                viewModel.selection.insert(id)
            }
        }
    }
    
    @ViewBuilder
    private func editableTextField(for itemBinding: Binding<SetlistItem>) -> some View {
        let item = itemBinding.wrappedValue
        
        let commitChanges = {
            var updatedItem = itemBinding.wrappedValue
            if item.type == .song { updatedItem.songTitle = editingText }
            else { updatedItem.markerDescription = editingText }
            viewModel.updateItem(updatedItem)
            viewModel.editingItemID = nil
        }
        
        let font: Font = (item.type == .song) ? .system(size: 48, weight: .bold) : .system(size: 20, weight: .regular)
        
        TextField("Enter Text", text: $editingText)
            .font(font)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.center)
            .padding(8)
            .focused($isEditingFocused)
            .onSubmit(commitChanges)
            .onExitCommand(perform: commitChanges)
    }
}

// A dedicated view for a drop zone.
struct DropZoneView: View {
    let insertionIndex: Int
    var isHorizontal: Bool = false
    @Binding var isDragging: Bool
    @ObservedObject var viewModel: LiveSetlistViewModel
    
    @State private var isTargeted = false

    var body: some View {
        Rectangle()
            .fill(isTargeted ? Color.gray.opacity(0.2) : Color.clear)
            .frame(width: isHorizontal ? 60 : nil, height: isHorizontal ? nil : 40)
            .frame(minHeight: isHorizontal ? 60 : nil)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isTargeted ? Color.white : Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [10]))
                    .opacity(isDragging ? 1 : 0)
            )
            .onDrop(of: [UTType.text], isTargeted: $isTargeted) { providers in
                guard let provider = providers.first else { return false }
                provider.loadObject(ofClass: NSString.self) { (string, error) in
                    guard let rawValue = string as? String,
                          let type = LiveSetlistViewModel.DraggableItem(rawValue: rawValue) else { return }
                    DispatchQueue.main.async {
                        viewModel.createAndAddItem(ofType: type, at: insertionIndex)
                    }
                }
                // Reset dragging state on successful drop
                DispatchQueue.main.async {
                    self.isDragging = false
                }
                return true
            }
            .onChange(of: isDragging) { _, newIsDragging in
                if !newIsDragging { isTargeted = false }
            }
    }
}
