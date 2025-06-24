import SwiftUI

struct StyledInputField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding(12)
            .background(Color.black.opacity(0.15))
            .cornerRadius(10)
            .font(.body)
            .textFieldStyle(PlainTextFieldStyle())
    }
}
