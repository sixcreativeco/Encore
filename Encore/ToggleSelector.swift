import SwiftUI

struct ToggleSelector: View {
    @Binding var selected: String
    var options: [String]
    var onChange: ((String) -> Void)? = nil

    var body: some View {
        HStack {
            ForEach(options, id: \.self) { option in
                Button(option) {
                    selected = option
                    onChange?(option)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(selected == option ? Color.gray.opacity(0.3) : Color.clear)
                .cornerRadius(10)
            }
        }
    }
}
