import SwiftUI
import UniformTypeIdentifiers

struct SetlistDropDelegate: DropDelegate {
    let item: SetlistItem
    @Binding var items: [SetlistItem]
    @Binding var draggedItem: SetlistItem?

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = self.draggedItem else {
            return false
        }
        
        if let fromIndex = items.firstIndex(of: draggedItem),
           let toIndex = items.firstIndex(of: item) {
            
            items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            
            // The view model will be responsible for persisting this change.
        }
        
        self.draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = self.draggedItem, draggedItem != item,
              let fromIndex = items.firstIndex(of: draggedItem),
              let toIndex = items.firstIndex(of: item)
        else {
            return
        }
        
        if items[toIndex] != draggedItem {
            withAnimation {
                items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
