import SwiftUI
import FirebaseFirestore

struct AddCrewSectionView: View {
    let tourID: String
    @EnvironmentObject var appState: AppState

    // FIX: The State variable now uses our new, Codable TourCrew model.
    @State private var crewMembers: [TourCrew] = []
    @State private var newCrewName: String = ""
    @State private var newCrewEmail: String = ""
    @State private var roleInput: String = ""
    @State private var selectedRoles: [String] = []
    @State private var showRoleSuggestions: Bool = false
    @State private var selectedVisibility: String = "full"
    @State private var showVisibilityOptions: Bool = false

    @State private var emailValidationState: EmailValidationState = .none
    @State private var emailCheckTask: Task<Void, Never>? = nil
    
    // This will hold the listener so we can detach it when the view disappears.
    @State private var listener: ListenerRegistration?

    private enum EmailValidationState { case none, checking, valid, invalid }

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
        return roleOptions.filter {
            !$0.isEmpty && $0.lowercased().contains(roleInput.lowercased()) && !selectedRoles.contains($0)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Crew").font(.headline)

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    CustomTextField(placeholder: "Name", text: $newCrewName)
                    HStack(spacing: 8) {
                        CustomTextField(placeholder: "Email", text: $newCrewEmail)
                        switch emailValidationState {
                        case .checking:
                            ProgressView().scaleEffect(0.5)
                        case .valid:
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        default:
                            EmptyView().frame(width: 20)
                        }
                    }
                }
                .onChange(of: newCrewEmail) { _, newValue in
                    checkEmailWithDebounce(email: newValue)
                }

                VStack(spacing: 4) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(selectedRoles, id: \.self) { role in
                                HStack(spacing: 6) {
                                    Text(role).font(.subheadline)
                                    Button(action: { selectedRoles.removeAll { $0 == role } }) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.gray)
                                    }.buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2)).cornerRadius(6)
                            }
                            TextField("Type a role", text: $roleInput)
                                .textFieldStyle(PlainTextFieldStyle()).frame(minWidth: 100)
                                .onChange(of: roleInput) { _, value in
                                    showRoleSuggestions = !value.isEmpty
                                }.onSubmit { addCustomRole() }
                        }
                        .padding(.horizontal, 8).padding(.vertical, 6)
                    }
                    .frame(height: 42).background(Color.gray.opacity(0.05)).cornerRadius(8)

                    ZStack {
                        if showRoleSuggestions && !filteredRoles.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(filteredRoles.prefix(5), id: \.self) { suggestion in
                                    Button(action: {
                                        selectedRoles.append(suggestion)
                                        roleInput = ""
                                        showRoleSuggestions = false
                                    }) {
                                        Text(suggestion)
                                            .frame(maxWidth: .infinity, alignment: .leading).padding(8)
                                    }.buttonStyle(.plain)
                                }
                            }
                            .background(Color(NSColor.windowBackgroundColor)).cornerRadius(6).shadow(radius: 1).padding(.top, 4)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Visibility").font(.subheadline).bold()
                    VStack(spacing: 0) {
                        Button(action: { withAnimation { showVisibilityOptions.toggle() } }) {
                            HStack {
                                Text(visibilityTitle(for: selectedVisibility))
                                    .font(.subheadline).foregroundColor(.primary)
                                Spacer()
                                Image(systemName: showVisibilityOptions ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .bold)).foregroundColor(.gray)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 12)
                            .background(Color.gray.opacity(0.05)).cornerRadius(8)
                        }.frame(width: 200)

                        if showVisibilityOptions {
                            VStack(spacing: 0) {
                                ForEach(visibilityOptions, id: \.self) { option in
                                    Button(action: {
                                        selectedVisibility = option
                                        showVisibilityOptions = false
                                    }) {
                                        Text(visibilityTitle(for: option))
                                            .padding(.vertical, 12).padding(.horizontal, 12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.plain).foregroundColor(.primary)
                                }
                            }
                            .background(Color(NSColor.windowBackgroundColor)).cornerRadius(8).shadow(radius: 2).padding(.top, 4)
                        }
                    }
                    Text(visibilityDescription(for: selectedVisibility))
                        .font(.footnote).foregroundColor(.gray).lineLimit(3)
                        .multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading)
                }
                Button(action: { saveCrewMember() }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Crew Member")
                    }
                }.font(.subheadline)
            }

            // This is the list that provides the visual confirmation.
            VStack(alignment: .leading, spacing: 8) {
                // FIX: This now iterates over the new [TourCrew] model.
                ForEach(crewMembers) { member in
                    VStack(alignment: .leading) {
                        Text("\(member.name) • \(member.roles.joined(separator: ", "))").font(.subheadline)
                        if let email = member.email, !email.isEmpty {
                            Text(email).font(.caption).foregroundColor(.gray)
                        }
                    }
                    .padding(8).background(Color.gray.opacity(0.05)).cornerRadius(8)
                }
            }
        }
        .padding(.top, 12)
        .onAppear { loadCrew() }
        .onDisappear { listener?.remove() } // Make sure to clean up the listener
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
                FirebaseUserService.shared.checkUserExists(byEmail: trimmedEmail) { foundUserID in
                    DispatchQueue.main.async {
                        self.emailValidationState = (foundUserID != nil) ? .valid : .invalid
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.emailValidationState = .none
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
        guard !newCrewName.isEmpty, !selectedRoles.isEmpty, let ownerId = appState.userID else { return }
        let newCrew = TourCrew(
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
            _ = try Firestore.firestore().collection("tourCrew").addDocument(from: newCrew)
            newCrewName = ""; newCrewEmail = ""; roleInput = ""; selectedRoles = []; selectedVisibility = "full"
        } catch {
            print("❌ Error saving new crew member: \(error.localizedDescription)")
        }
    }
    
    // --- FIX IS HERE ---
    private func loadCrew() {
        listener?.remove() // Prevent duplicate listeners
        let db = Firestore.firestore()
        
        // This now listens for real-time updates on the top-level /tourCrew collection
        // and filters for the current tour. This will make the list update instantly.
        listener = db.collection("tourCrew")
            .whereField("tourId", isEqualTo: tourID)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error loading crew: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                // We use Codable to automatically decode into our new TourCrew model.
                self.crewMembers = documents.compactMap { try? $0.data(as: TourCrew.self) }
            }
    }
}
