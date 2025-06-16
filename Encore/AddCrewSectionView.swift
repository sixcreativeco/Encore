import SwiftUI
import FirebaseFirestore

struct AddCrewSectionView: View {
    let tourID: String

    @State private var crewMembers: [CrewMember] = []
    @State private var newCrewName: String = ""
    @State private var newCrewEmail: String = ""
    @State private var roleInput: String = ""
    @State private var selectedRoles: [String] = []
    @State private var showRoleSuggestions: Bool = false

    @State private var roleOptions: [String] = [
        "Lead Artist", "Support Artist", "DJ", "Dancer", "Guest Performer", "Musician",
        "Content", "Tour Manager", "Artist Manager", "Road Manager", "Assistant Manager",
        "Tour Accountant", "Advance Coordinator", "Production Manager", "Stage Manager",
        "Lighting", "Sound", "Audio Tech", "Video", "Playback Operator", "Backline Tech",
        "Rigger", "SFX", "Driver", "Transport Coordinator", "Logistics", "Fly Tech",
        "Local Runner", "Security", "Assistant", "Stylist", "Hair and Makeup", "Catering",
        "Merch Manager", "Wellness", "PA", "Childcare", "Label Rep", "Marketing",
        "Street Team", "Promoter Rep", "Merch Staff", "Translator", "Drone Op",
        "Content Creator", "Custom"
    ]

    var filteredRoles: [String] {
        guard !roleInput.isEmpty else { return [] }
        return roleOptions.filter {
            !$0.isEmpty && $0.lowercased().contains(roleInput.lowercased()) && !selectedRoles.contains($0)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Crew").font(.headline)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    CustomTextField(placeholder: "Name", text: $newCrewName)
                    CustomTextField(placeholder: "Email", text: $newCrewEmail)

                    ZStack(alignment: .topLeading) {
                        VStack(spacing: 0) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(selectedRoles, id: \.self) { role in
                                        HStack(spacing: 6) {
                                            Text(role).font(.subheadline)
                                            Button(action: { selectedRoles.removeAll { $0 == role } }) {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.gray)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(6)
                                    }

                                    TextField("Type a role", text: $roleInput)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .frame(minWidth: 100)
                                        .onChange(of: roleInput) { value in
                                            showRoleSuggestions = !value.isEmpty
                                        }
                                        .onSubmit {
                                            addCustomRole()
                                        }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                            }
                            .frame(height: 42)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                        }

                        if showRoleSuggestions && !filteredRoles.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(filteredRoles.prefix(5), id: \.self) { suggestion in
                                    Button(action: {
                                        selectedRoles.append(suggestion)
                                        roleInput = ""
                                        showRoleSuggestions = false
                                    }) {
                                        Text(suggestion)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(8)
                                    }
                                }
                            }
                            .background(.background)
                            .cornerRadius(6)
                            .shadow(radius: 1)
                            .offset(y: 50)
                            .zIndex(1)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150) // <-- This locks the full height so layout never shifts
                }

                Button(action: { saveCrewMember() }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Crew Member")
                    }
                }
                .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(crewMembers, id: \.name) { member in
                    VStack(alignment: .leading) {
                        Text("\(member.name) • \(member.roles.joined(separator: ", "))").font(.subheadline)
                        if !member.email.isEmpty {
                            Text(member.email).font(.caption).foregroundColor(.gray)
                        }
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.top, 12)
        .onAppear { loadCrew() }
    }

    private func addCustomRole() {
        let trimmedRole = roleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRole.isEmpty else { return }
        if !roleOptions.contains(trimmedRole) {
            roleOptions.append(trimmedRole)
        }
        selectedRoles.append(trimmedRole)
        roleInput = ""
        showRoleSuggestions = false
    }

    private func saveCrewMember() {
        guard !newCrewName.isEmpty, !selectedRoles.isEmpty else { return }

        let db = Firestore.firestore()
        let crewData: [String: Any] = [
            "name": newCrewName.trimmingCharacters(in: .whitespaces),
            "email": newCrewEmail.trimmingCharacters(in: .whitespaces),
            "roles": selectedRoles,
            "createdAt": Date()
        ]

        db.collection("users")
            .document(AuthManager.shared.user?.uid ?? "")
            .collection("tours")
            .document(tourID)
            .collection("crew")
            .addDocument(data: crewData) { error in
                if error == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        loadCrew()
                    }
                }
            }

        newCrewName = ""
        newCrewEmail = ""
        roleInput = ""
        selectedRoles = []
    }

    private func loadCrew() {
        let db = Firestore.firestore()
        db.collection("users")
            .document(AuthManager.shared.user?.uid ?? "")
            .collection("tours")
            .document(tourID)
            .collection("crew")
            .getDocuments { snapshot, _ in
                self.crewMembers = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    let name = data["name"] as? String ?? ""
                    let email = data["email"] as? String ?? ""
                    let roles = data["roles"] as? [String] ?? []
                    return CrewMember(name: name, email: email, roles: roles)
                } ?? []
            }
    }
}
