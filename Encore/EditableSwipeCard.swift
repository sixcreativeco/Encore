import SwiftUI

struct EditableSwipeCard<Content: View>: View {
    let content: () -> Content
    let onDelete: () -> Void
    let onEdit: () -> Void

    init(onDelete: @escaping () -> Void, onEdit: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.onDelete = onDelete
        self.onEdit = onEdit
        self.content = content
    }

    var body: some View {
        content()
            .swipeActions(edge: .trailing) {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .leading) {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
            }
    }
}
