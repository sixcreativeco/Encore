import SwiftUI
import FirebaseFirestore

struct SupportActPickerView: View {
    var tourID: String
    var userID: String
    @Binding var selectedSupportActs: [String]

    @State private var supportActInput: String = ""
    @State private var allSupportActs: [String] = []

    var filteredSuggestions: [String] {
        guard !supportActInput.isEmpty else { return [] }
        return allSupportActs.filter {
            $0.lowercased().hasPrefix(supportActInput.lowercased()) && !selectedSupportActs.contains($0)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Support Acts").font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedSupportActs, id: \.self) { act in
                        HStack {
                            Text(act)
                            Button(action: { selectedSupportActs.removeAll { $0 == act } }) {
                                Image(systemName: "xmark.circle.fill").font(.caption)
                            }
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.gray.opacity(0.15)).cornerRadius(8)
                    }

                    TextField("Add Support Act", text: $supportActInput)
                        .textFieldStyle(PlainTextFieldStyle())
                        .frame(minWidth: 150)
                        .onChange(of: supportActInput) { _ in }
                }
                .padding(8).background(Color.gray.opacity(0.05)).cornerRadius(8)
            }

            if !filteredSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredSuggestions.prefix(5), id: \.self) { suggestion in
                        Button(action: {
                            selectedSupportActs.append(suggestion)
                            supportActInput = ""
                        }) {
                            Text(suggestion).padding(8).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .background(Color.white).cornerRadius(6).shadow(radius: 1)
            }

            if !supportActInput.isEmpty && !allSupportActs.contains(supportActInput) {
                Button("Add \"\(supportActInput)\"") {
                    selectedSupportActs.append(supportActInput)
                    saveSupportActName(supportActInput)
                    supportActInput = ""
                }
                .font(.subheadline)
            }
        }
        .onAppear { fetchSupportActs() }
    }

    private func fetchSupportActs() {
        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("tours").document(tourID).collection("supportActs")
            .order(by: "name").getDocuments { snapshot, _ in
                self.allSupportActs = snapshot?.documents.compactMap { $0["name"] as? String } ?? []
            }
    }

    private func saveSupportActName(_ name: String) {
        let db = Firestore.firestore()
        let ref = db.collection("users").document(userID).collection("tours").document(tourID).collection("supportActs").document()
        ref.setData([
            "name": name,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }
}
