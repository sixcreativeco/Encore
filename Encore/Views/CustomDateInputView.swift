import SwiftUI

struct CustomDateInputView: View {
    let label: String
    @Binding var date: Date

    @State private var isPopoverPresented: Bool = false

    // A formatter to display the date to the user.
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy" // e.g., 28 Aug 2025
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)

            // --- FIX: Replaced TextField with a Button to prevent invalid input and state loops ---
            Button(action: { isPopoverPresented = true }) {
                HStack {
                    Text(Self.formatter.string(from: date))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                }
                .padding(12)
            }
            .buttonStyle(.plain)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)
            .popover(isPresented: $isPopoverPresented) {
                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .onChange(of: date) { _ in
                    // Dismiss the popover when a new date is selected
                    isPopoverPresented = false
                }
            }
        }
    }
}
