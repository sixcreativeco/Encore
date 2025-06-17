import SwiftUI

struct SortableHeader: View {
    let title: String
    let field: String
    @Binding var sortField: String
    @Binding var sortAscending: Bool

    var body: some View {
        Button(action: {
            if sortField == field {
                sortAscending.toggle()
            } else {
                sortField = field
                sortAscending = true
            }
        }) {
            HStack(spacing: 4) {
                Text(title).bold()
                if sortField == field {
                    Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}
