import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddCrewSectionView: View {
    let tourID: String
    @EnvironmentObject var appState: AppState

    @State private var crewMembers: [TourCrew] = []
    @State private var newCrewName: String = ""
    @State private var newCrewEmail: String = ""
    @State private var roleInput: String = ""
    @State private var selectedRoles: [String] = []
    @State private var showRoleSuggestions: Bool = false
    
    // State for email validation
    @State private var foundUserId: String?
    private enum EmailValidationState { case none, checking, valid, invalid }
    @State private var emailValidationState: EmailValidationState = .none
    @State private var emailCheckTask: Task<Void, Never>? = nil
    
    @State private var listener: ListenerRegistration?
    
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
                                .background(Color.black.opacity(0.2)).cornerRadius(6)
                            }
                            TextField("Type a role", text: $roleInput)
                                .textFieldStyle(PlainTextFieldStyle()).frame(minWidth: 100)
                                .onChange(of: roleInput) { _, value in
                                    showRoleSuggestions = !value.isEmpty
                                }.onSubmit { addCustomRole() }
                        }
                        .padding(.horizontal, 8).padding(.vertical, 6)
                    }
                    .frame(height: 42)
                    .background(Color.black.opacity(0.15))
                    .cornerRadius(8)

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

                Button(action: { saveCrewMember() }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Crew Member")
                    }
                }
                .font(.subheadline)
            }
            .padding()
            .background(Color.black.opacity(0.15))
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(crewMembers) { member in
                    VStack(alignment: .leading) {
                        Text("\(member.name) • \(member.roles.joined(separator: ", "))").font(.subheadline)
                        if let email = member.email, !email.isEmpty {
                            Text(email).font(.caption).foregroundColor(.gray)
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.15))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.top, 12)
        .onAppear { loadCrew() }
        .onDisappear { listener?.remove() }
    }

    private func checkEmailWithDebounce(email: String) {
        emailCheckTask?.cancel()
        foundUserId = nil
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
                FirebaseUserService.shared.checkUserExists(byEmail: trimmedEmail) { foundID in
                    DispatchQueue.main.async {
                        self.foundUserId = foundID
                        self.emailValidationState = (foundID != nil) ? .valid : .invalid
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.emailValidationState = .none
                }
            }
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
        guard !newCrewName.isEmpty, !selectedRoles.isEmpty, let ownerId = appState.userID, let currentTour = appState.tours.first(where: { $0.id == tourID }) else { return }
        
        let newCrew = TourCrew(
            tourId: self.tourID,
            userId: foundUserId,
            contactId: nil,
            name: newCrewName.trimmingCharacters(in: .whitespaces),
            email: newCrewEmail.trimmingCharacters(in: .whitespaces).lowercased(),
            roles: selectedRoles,
            visibility: .full, // Defaulting to full, as this view has no picker
            status: foundUserId != nil ? .pending : .invited, // Set status based on email check
            invitationCode: nil, // Invitation code generation is handled by AddCrewPopupView
            startDate: nil,
            endDate: nil,
            invitedBy: ownerId
        )

        do {
            let ref = try Firestore.firestore().collection("tourCrew").addDocument(from: newCrew)
            
            // If the user exists, send them a notification
            if let recipientId = foundUserId {
                FirebaseUserService.shared.createInvitationNotification(
                    for: currentTour,
                    recipientId: recipientId,
                    inviterId: ownerId,
                    inviterName: Auth.auth().currentUser?.displayName ?? "An Encore User",
                    crewDocId: ref.documentID,
                    roles: selectedRoles
                )
            }
            
            // Reset fields
            newCrewName = ""; newCrewEmail = ""; roleInput = ""; selectedRoles = [];
            foundUserId = nil; emailValidationState = .none
        } catch {
            print("❌ Error saving new crew member: \(error.localizedDescription)")
        }
    }
    
    private func loadCrew() {
        listener?.remove()
        let db = Firestore.firestore()
        
        listener = db.collection("tourCrew")
            .whereField("tourId", isEqualTo: tourID)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error loading crew: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                self.crewMembers = documents.compactMap { try? $0.data(as: TourCrew.self) }
            }
    }
}
