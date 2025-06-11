import SwiftUI

struct StyledTimePicker: View {
    var label: String
    @Binding var time: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !label.isEmpty {
                Text(label).font(.subheadline.bold())
            }
            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .padding(12)
                .background(Color.gray.opacity(0.06))
                .cornerRadius(10)
                .datePickerStyle(.compact)
                .frame(height: 44)
        }
    }
}
