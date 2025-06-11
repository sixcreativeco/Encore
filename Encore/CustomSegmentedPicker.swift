import SwiftUI

struct CustomSegmentedPicker<T: Hashable & CustomStringConvertible>: View {
    @Binding var selected: T
    var options: [T]
    var labels: [String]? = nil

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selected = option
                }) {
                    Text(labels?[options.firstIndex(of: option) ?? 0] ?? option.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selected == option ? .white : .black)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(selected == option ? Color.black : Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

extension Bool: CustomStringConvertible {
    public var description: String {
        self ? "Yes" : "No"
    }
}
