import SwiftUI

struct CustomSearchField<ResultType: Identifiable & CustomStringConvertible>: View {
    let placeholder: String
    @Binding var text: String
    var results: [ResultType]
    var onSelect: (ResultType) -> Void

    @State private var showDropdown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(placeholder, text: $text, onEditingChanged: { editing in
                showDropdown = editing
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onChange(of: text) { _ in
                showDropdown = true
            }

            if showDropdown && !results.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(results) { result in
                            Button(action: {
                                onSelect(result)
                                showDropdown = false
                            }) {
                                Text(result.description)
                                    .foregroundColor(.primary)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(nsColor: .controlBackgroundColor))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .frame(maxHeight: 150)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                .shadow(radius: 2)
            }
        }
    }
}
