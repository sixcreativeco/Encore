import SwiftUI

struct StyledDropdown: View {
    let label: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline.bold())
                .foregroundColor(.gray)

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(action: { selection = option }) {
                        Text(option)
                    }
                }
            } label: {
                HStack {
                    Text(selection.isEmpty ? "Select" : selection)
                        .foregroundColor(selection.isEmpty ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(12)
                .background(Color.gray.opacity(0.06))
                .cornerRadius(10)
            }
        }
    }
}
