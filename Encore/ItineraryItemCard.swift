import SwiftUI

struct ItineraryItemCard: View {
    let item: ItineraryItemModel
    let isExpanded: Bool
    let onExpandToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    // Local colors locked inside this file
    private let editColor = Color(red: 116/255, green: 151/255, blue: 173/255)
    private let deleteColor = Color(red: 193/255, green: 106/255, blue: 106/255)

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: item.type.iconName)
                        .font(.title2)
                    Text(item.title).font(.headline)
                    Spacer()
                    Text(item.time.formatted(date: .omitted, time: .shortened))
                }
                if let note = item.note, !note.isEmpty {
                    Text(note).font(.subheadline).foregroundColor(.gray)
                }
            }
            .padding()

            if isExpanded {
                VStack(spacing: 16) {
                    HStack(spacing: 24) {
                        Button(action: { onEdit() }) {
                            Text("Edit")
                                .fontWeight(.semibold)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .background(editColor)
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)

                        Button(action: { onDelete() }) {
                            Text("Delete")
                                .fontWeight(.semibold)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .background(deleteColor)
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 16)
                .padding(.bottom, 12)
                .transition(.opacity)
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
        .contentShape(Rectangle())
        .onTapGesture {
            onExpandToggle()
        }
    }
}
