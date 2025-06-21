import SwiftUI
import FirebaseFirestore

struct AddCrewPopupView: View {
    let tourID: String
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState

    @State private var newCrewName: String = ""
    @State private var newCrewEmail: String = ""
    @State private var roleInput: String = ""
    @State private var selectedRoles: [String] = []
    @State private var showRoleSuggestions: Bool = false
    @State private var selectedVisibility: String = "full"
    @State private var showVisibilityOptions: Bool = false
    
    private enum EmailValidationState { case none, checking, valid, invalid }
    @State private var emailValidationState: EmailValidationState = .none
    @State private var emailCheckTask: Task<Void, Never>? = nil

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
        .background(Color.accentColor)
        .foregroundColor(.white)
        .cornerRadius(12)
        .padding(.top, 24)
    }

    private var inputFields: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                CustomTextField(placeholder: "Name", text: $newCrewName)
                
                HStack(spacing: 8) {
                    CustomTextField(placeholder: "Email", text: $newCrewEmail)
                    
                    switch emailValidationState {
                    case .checking:
                        ProgressView().scaleEffect(0.5)
                    case .valid:
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    case .invalid:
                        EmptyView().frame(width: 20)
                    case .none:
                        EmptyView().frame(width: 20)
                    }
                }
            }
            .onChange(of: newCrewEmail) { _, newValue in
                checkEmailWithDebounce(email: newValue)
            }

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
                                .onChange(of: roleInput) { _, value in
                                    showRoleSuggestions = !value.isEmpty
                                }
                                .onSubmit { addCustomRole() }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    }
                    .frame(height: 42)
                    .background(Color(nsColor: .controlBackgroundColor))
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
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
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

            VStack(alignment: .leading, spacing: 8) {
                Text("Visibility").font(.subheadline).bold()

                ZStack(alignment: .topLeading) {
                    HStack(alignment: .top, spacing: 8) {
                        Button(action: { withAnimation { showVisibilityOptions.toggle() } }) {
                            HStack {
                                Text(visibilityTitle(for: selectedVisibility))
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: showVisibilityOptions ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.gray)
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
                                    Text(visibilityTitle(for: option))
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .foregroundColor(.primary)
                            }
                        }
                        .background(.background)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .frame(width: 200)
                        .offset(y: 45)
                        .zIndex(10)
                    }
                }
                .frame(height: 70, alignment: .top)
            }
        }
    }
    
    private func checkEmailWithDebounce(email: String) {
        emailCheckTask?.cancel()
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmedEmail.isEmpty, trimmedEmail.contains("@") else {
            emailValidationState = .none
            return
        }

        emailValidationState = .checking
        
        emailCheckTask = Task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
                guard !Task.isCancelled else { return }
                
                // FirebaseUserService.shared.checkUserExists(...)
            } catch {
                DispatchQueue.main.async {
                    self.emailValidationState = .invalid
                }
            }
        }
    }

    private func visibilityTitle(for option: String) -> String {
        switch option {
        case "full": return "Full"
        case "limited": return "Limited"
        case "temporary": return "Temporary"
        default: return option
        }
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
        if !roleOptions.contains(trimmedRole) {
            roleOptions.append(trimmedRole)
        }
        selectedRoles.append(trimmedRole)
        roleInput = ""
        showRoleSuggestions = false
    }

    private func saveCrewMember() {
        guard !newCrewName.isEmpty, !selectedRoles.isEmpty, !newCrewEmail.isEmpty, let ownerId = appState.userID else { return }

        let newCrewMember = TourCrew(
            tourId: self.tourID,
            userId: nil,
            contactId: nil,
            name: newCrewName.trimmingCharacters(in: .whitespaces),
            email: newCrewEmail.trimmingCharacters(in: .whitespaces).lowercased(),
            roles: selectedRoles,
            visibility: TourCrew.CrewVisibility(rawValue: selectedVisibility) ?? .full,
            invitedBy: ownerId
        )

        do {
            _ = try Firestore.firestore().collection("tourCrew").addDocument(from: newCrewMember)
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("❌ Error saving new crew member: \(error.localizedDescription)")
        }
    }
}
