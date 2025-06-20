import SwiftUI

// A reusable styled TextEditor that includes a placeholder.
struct CustomTextEditor: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray.opacity(0.75))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .allowsHitTesting(false)
            }
            
            TextEditor(text: $text)
                .scrollContentBackground(.hidden) // Make background transparent
                .padding(4)
                .frame(minHeight: 80, alignment: .top)
        }
        .background(Color.gray.opacity(0.06))
        .cornerRadius(10)
    }
}
