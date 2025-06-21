import SwiftUI

struct ItineraryItemCard: View {
    // FIX: Updated to use the new 'ItineraryItem' model.
    let item: ItineraryItem
    
    // These properties are kept for API compatibility with the parent view.
    let isExpanded: Bool
    let onExpandToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        // The overall UI structure is preserved.
        Button(action: onExpandToggle) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // FIX: Gets the icon by converting the 'type' string into our ItineraryItemType enum.
                        // This resolves the "no member 'iconName'" error.
                        Image(systemName: ItineraryItemType(rawValue: item.type)?.iconName ?? "questionmark.circle")
                            .font(.title2)
                        
                        Text(item.title).font(.headline)
                        Spacer()
                        
                        // FIX: Uses the new timeUTC property and gets its dateValue().
                        Text(item.timeUTC.dateValue().formatted(date: .omitted, time: .shortened))
                    }

                    if let subtitle = item.subtitle, !subtitle.isEmpty {
                        Text(subtitle).font(.subheadline).foregroundColor(.gray)
                    }
                    
                    // FIX: Uses the new 'notes' property (plural).
                    if let note = item.notes, !note.isEmpty {
                        Text(note).font(.subheadline).foregroundColor(.gray)
                    }
                }
                .padding()

                if isExpanded {
                    // The expanded view with Edit/Delete buttons remains unchanged.
                    expandedActionView
                }
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
    
    private var expandedActionView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                Button(action: onEdit) {
                    Text("Edit")
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(Color(red: 116/255, green: 151/255, blue: 173/255))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Text("Delete")
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(Color(red: 193/255, green: 106/255, blue: 106/255))
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
