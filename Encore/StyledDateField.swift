import SwiftUI

struct StyledDateField: View {
    @Binding var date: Date

    var body: some View {
        DatePicker("", selection: $date, displayedComponents: [.date])
            .labelsHidden()
            .padding(12)
            .background(Color.gray.opacity(0.06))
            .cornerRadius(10)
            .datePickerStyle(.compact)
            .frame(maxWidth: 200)
    }
}
