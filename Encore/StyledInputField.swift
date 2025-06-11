import SwiftUI

struct StyledInputField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(placeholder).font(.subheadline.bold())
            TextField("", text: $text)
                .padding(12)
                .background(Color.gray.opacity(0.06))
                .cornerRadius(10)
                .font(.body)
                .textFieldStyle(PlainTextFieldStyle())
        }
    }
}
