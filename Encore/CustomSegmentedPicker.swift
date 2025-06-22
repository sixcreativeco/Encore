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
                        // FIX: Added frame to make buttons expand to fill space
                        .frame(maxWidth: .infinity)
                        // FIX: Updated colors to match new design
                        .foregroundColor(selected == option ? .black : .white.opacity(0.7))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        // FIX: Updated backgrounds to match new design
                        .background(selected == option ? Color.white : Color.white.opacity(0.1))
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
