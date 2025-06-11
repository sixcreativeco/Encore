import SwiftUI

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
            }

            TextField("", text: $text)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.clear)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}
