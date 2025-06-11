import SwiftUI

struct TokenSelectorView: View {
    let allTokens: [String]
    @Binding var selectedTokens: [String]
    var placeholder: String

    @State private var searchText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField(placeholder, text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: searchText) { _ in
                        if let exactMatch = allTokens.first(where: { $0.lowercased() == searchText.lowercased() }),
                           !selectedTokens.contains(exactMatch) {
                            selectedTokens.append(exactMatch)
                            searchText = ""
                        }
                    }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(selectedTokens, id: \.self) { token in
                            HStack(spacing: 6) {
                                Text(token)
                                Image(systemName: "xmark.circle.fill")
                                    .onTapGesture {
                                        selectedTokens.removeAll { $0 == token }
                                    }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                        }
                    }
                }
            }

            if !searchText.isEmpty {
                ForEach(allTokens.filter {
                    $0.lowercased().contains(searchText.lowercased()) && !selectedTokens.contains($0)
                }, id: \.self) { match in
                    Text(match)
                        .onTapGesture {
                            selectedTokens.append(match)
                            searchText = ""
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .frame(minWidth: 200)
    }
}
