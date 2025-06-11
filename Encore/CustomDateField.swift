import SwiftUI

struct CustomDateField: View {
    @Binding var date: Date
    @State private var isShowingCalendar = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))

            Button(action: {
                isShowingCalendar.toggle()
            }) {
                HStack {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .foregroundColor(.primary)
                        .padding(.leading, 4)

                    Spacer()

                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $isShowingCalendar, arrowEdge: .bottom) {
                VStack {
                    DatePicker(
                        "",
                        selection: $date,
                        displayedComponents: .date
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .labelsHidden()
                    .scaleEffect(1.2) // 👈 Only scales the calendar
                }
                .frame(width: 190, height: 200) // 👈 Adjusted to suit scaled calendar
            }
        }
        .frame(height: 36)
    }
}
