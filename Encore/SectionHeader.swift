import SwiftUI

struct SectionHeader: View {
    var title: String
    var onAdd: () -> Void

    var body: some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            Button(action: onAdd) {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(.plain)
        }
    }
}
