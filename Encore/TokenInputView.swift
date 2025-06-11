import SwiftUI

struct TokenInputView: View {
    @Binding var selectedTokens: [String]
    var allOptions: [String]
    var placeholder: String

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WrapView(items: selectedTokens) { token in
                HStack(spacing: 4) {
                    Text(token)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(6)

                    Button(action: {
                        selectedTokens.removeAll { $0 == token }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }

            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isFocused)
                .onChange(of: text) { newValue in
                    let match = allOptions.first(where: {
                        $0.lowercased().hasPrefix(newValue.lowercased())
                            && !selectedTokens.contains($0)
                    })

                    if let match = match, newValue.count > 2 {
                        selectedTokens.append(match)
                        text = ""
                    }
                }
        }
    }
}
