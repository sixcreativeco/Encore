import SwiftUI
import FirebaseFirestore

struct AddCrewPopupView: View {
    let tourID: String
    @Environment(\.presentationMode) var presentationMode

    @State private var newCrewName: String = ""
    @State private var newCrewEmail: String = ""
    @State private var roleInput: String = ""
    @State private var selectedRoles: [String] = []
    @State private var showRoleSuggestions: Bool = false
    @State private var selectedVisibility: String = "full"
    @State private var showVisibilityOptions: Bool = false
    @State private var matchingUserID: String? = nil

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

    let visibilityOptions: [String] = ["full", "limited", "temporary"]

    var filteredRoles: [String] {
        guard !roleInput.isEmpty else { return [] }
        let lowercaseInput = roleInput.lowercased()
        let availableRoles = roleOptions.filter { !$0.isEmpty && !selectedRoles.contains($0) }
        return availableRoles.filter { $0.lowercased().contains(lowercaseInput) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerView
            inputFields
            Spacer()
            addButton
        }
        .padding(32)
        .frame(minWidth: 500, minHeight: 600)
        .background(.background)
    }

    private var headerView: some View {
        HStack {
            Text("Add Crew").font(.title2).bold()
            Spacer()
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
        }
    }

    private var addButton: some View {
        Button(action: { saveCrewMember() }) {
            Text("Add Crew Member")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.gray.opacity(0))
        .foregroundColor(.primary)
        .cornerRadius(12)
        .padding(.top, 24)
    }

    private var inputFields: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                CustomTextField(placeholder: "Name", text: $newCrewName)
                ZStack(alignment: .trailing) {
                    CustomTextField(placeholder: "Email", text: $newCrewEmail)
                        .onChange(of: newCrewEmail) { value in checkEmail(value) }
                    
                    if let id = matchingUserID {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .padding(.trailing, 8)
                    }
                }
            }
            rolesField
            visibilityField
        }
    }

    private var rolesField: some View {
        VStack(spacing: 0) {
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
                            .onChange(of: roleInput) { value in showRoleSuggestions = !value.isEmpty }
                            .onSubmit { addCustomRole() }
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
                            Text(suggestion).padding(.vertical, 12).padding(.horizontal, 12).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.primary)
                    }
                }
                .background(.background)
                .cornerRadius(8)
                .shadow(radius: 2)
                .padding(.top, 8)
            }
        }
    }

    private var visibilityField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Visibility").font(.subheadline).bold()
            ZStack(alignment: .topLeading) {
                HStack(alignment: .top, spacing: 8) {
                    Button(action: { withAnimation { showVisibilityOptions.toggle() } }) {
                        HStack {
                            Text(visibilityTitle(for: selectedVisibility)).font(.subheadline).foregroundColor(.primary)
                            Spacer()
                            Image(systemName: showVisibilityOptions ? "chevron.up" : "chevron.down").font(.system(size: 12, weight: .bold)).foregroundColor(.gray)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .cornerRadius(8)
                    }
                    .frame(width: 200)
                    Text(visibilityDescription(for: selectedVisibility))
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 70)
                
                if showVisibilityOptions {
                    VStack(spacing: 0) {
                        ForEach(visibilityOptions, id: \.self) { option in
                            Button(action: {
                                selectedVisibility = option
                                showVisibilityOptions = false
                            }) {
                                Text(visibilityTitle(for: option)).padding(.vertical, 12).padding(.horizontal, 12).frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(PlainButtonStyle()).foregroundColor(.primary)
                        }
                    }
                    .background(.background).cornerRadius(8).shadow(radius: 2).frame(width: 200).position(x: 100, y: 120).zIndex(10)
                }
            }
            .frame(height: 70)
        }
    }

    private func checkEmail(_ email: String) {
        FirebaseUserService.shared.checkUserExists(byEmail: email) { userId in
            DispatchQueue.main.async {
                self.matchingUserID = userId
            }
        }
    }

    private func saveCrewMember() {
        guard !newCrewName.isEmpty, !selectedRoles.isEmpty else { return }
        let db = Firestore.firestore()
        let userID = AuthManager.shared.user?.uid ?? ""

        let crewData: [String: Any] = [
            "name": newCrewName.trimmingCharacters(in: .whitespaces),
            "email": newCrewEmail.trimmingCharacters(in: .whitespaces),
            "roles": selectedRoles,
            "visibility": selectedVisibility,
            "createdAt": Date()
        ]

        db.collection("users").document(userID).collection("tours").document(tourID).collection("crew").addDocument(data: crewData)

        if let matchedUser = matchingUserID {
            FirebaseUserService.shared.addSharedTour(for: matchedUser, tourID: tourID, creatorUserID: userID, role: selectedRoles, visibility: selectedVisibility)
        }

        presentationMode.wrappedValue.dismiss()
    }

    private func visibilityTitle(for option: String) -> String {
        switch option { case "full": return "Full"; case "limited": return "Limited"; case "temporary": return "Temporary"; default: return option }
    }

    private func visibilityDescription(for option: String) -> String {
        let name = newCrewName.isEmpty ? "They" : newCrewName
        switch option {
        case "full": return "\(name) can see the full itinerary. Best for core crew, admins, and agents."
        case "limited": return "\(name) can see most details. Good for production and show crew."
        case "temporary": return "\(name) can see show times and assigned items only. Best for support acts and one-offs."
        default: return ""
        }
    }

    private func addCustomRole() {
        let trimmedRole = roleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRole.isEmpty else { return }
        if !roleOptions.contains(trimmedRole) { roleOptions.append(trimmedRole) }
        selectedRoles.append(trimmedRole)
        roleInput = ""; showRoleSuggestions = false
    }
}
