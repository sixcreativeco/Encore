import SwiftUI

/// A dynamic time picker component that can be included, removed, or have its time cleared.
struct DynamicTimingPicker: View {
    let type: ItineraryItemType
    @Binding var timings: [ItineraryItemType: Date?]

    /// A binding to determine if this specific timing type exists in the dictionary.
    private var isIncluded: Binding<Bool> {
        Binding<Bool>(
            get: { timings.keys.contains(type) },
            set: { isIncluded in
                withAnimation {
                    if isIncluded {
                        // When adding a timing back, default its time to noon.
                        timings[type] = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())
                    } else {
                        // When removing a timing, remove its key from the dictionary.
                        timings.removeValue(forKey: type)
                    }
                }
            }
        )
    }
    
    /// A binding to the date value for this specific timing type.
    private var dateSelection: Binding<Date?> {
        Binding<Date?>(
            get: { timings[type] ?? nil },
            set: { timings[type] = $0 }
        )
    }

    var body: some View {
        if isIncluded.wrappedValue {
            // If the timing is included, show the picker with a remove button.
            ZStack(alignment: .topTrailing) {
                OptionalTimePicker(label: type.displayName, selection: dateSelection)
                
                Button(action: {
                    isIncluded.wrappedValue = false // This will remove the key from the dictionary
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .offset(x: 8, y: -8)
            }
        } else {
            // If the timing has been removed, show a placeholder to add it back.
            TimingPlaceholderView(label: type.displayName) {
                isIncluded.wrappedValue = true // This will add the key back to the dictionary
            }
        }
    }
}


/// A simple time picker for an optional Date. (This is a simplified helper)
fileprivate struct OptionalTimePicker: View {
    let label: String
    @Binding var selection: Date?

    private var dateBinding: Binding<Date> {
        Binding<Date>(
            get: { self.selection ?? Date() },
            set: { self.selection = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline.bold())
                .foregroundColor(.gray)

            DatePicker(
                "",
                selection: dateBinding,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .padding(.leading, 8)
            .padding(.vertical, 7)
            .background(Color.gray.opacity(0.06))
            .cornerRadius(10)
            .frame(height: 44)
        }
    }
}

/// A placeholder view for a timing that has been removed.
fileprivate struct TimingPlaceholderView: View {
    let label: String
    let onAdd: () -> Void
    
    var body: some View {
        Button(action: onAdd) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.title2)
                Text(label)
                    .font(.subheadline.bold())
            }
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, minHeight: 92)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .foregroundColor(Color.gray.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
    }
}
