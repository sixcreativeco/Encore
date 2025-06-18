import SwiftUI

// This creates a reusable secure field that matches your CustomTextField style.
struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        SecureField(placeholder, text: $text)
            .padding(12)
            .background(Color(.unemphasizedSelectedContentBackgroundColor))
            .cornerRadius(8)
            .textFieldStyle(.plain)
    }
}
