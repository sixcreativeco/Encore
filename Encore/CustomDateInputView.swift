import SwiftUI

struct CustomDateInputView: View {
    let label: String
    @Binding var date: Date

    @State private var dateString: String = ""
    @State private var isPopoverPresented: Bool = false

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)

            HStack(spacing: 0) {
                TextField(Self.formatter.dateFormat, text: $dateString)
                    .padding(12)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: dateString) { newValue in
                        // Attempt to parse the typed string into a date
                        if let newDate = Self.formatter.date(from: newValue) {
                            self.date = newDate
                        }
                    }
                
                Button(action: { isPopoverPresented = true }) {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isPopoverPresented) {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .onChange(of: date) { newDate in
                            // Update text field when popover date changes
                            self.dateString = Self.formatter.string(from: newDate)
                            isPopoverPresented = false
                        }
                }
            }
            .background(Color.gray.opacity(0.06))
            .cornerRadius(10)
            .onAppear {
                // Initialize the text field with the current date value
                self.dateString = Self.formatter.string(from: date)
            }
            .onChange(of: date) { newDate in
                // Keep text field in sync if the binding is changed externally
                let newDateString = Self.formatter.string(from: newDate)
                if newDateString != dateString {
                    dateString = newDateString
                }
            }
        }
    }
}
