import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import AppKit // Import AppKit for NSPasteboard

struct AddCrewPopupView: View {
    let tourID: String
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState

    @State private var newCrewName: String = ""
    @State private var newCrewEmail: String = ""
    @State private var roleInput: String = ""
    @State private var selectedRoles: [String] = []
    @State private var showRoleSuggestions: Bool = false
    @State private var selectedVisibility: CrewVisibility = .full
    @State private var showVisibilityOptions: Bool = false
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    @State private var foundUserId: String?
    @State private var generatedCode: String?
    @State private var isSaving = false
    @State private var inviteSentSuccessfully = false
    
    private enum EmailValidationState { case none, checking, valid, invalid, info }
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
            if selectedVisibility == .temporary {
                dateRangePicker
            }
            if let code = generatedCode {
                invitationCodeView(code: code)
            }
            Spacer()
            actionButton
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

    private var actionButton: some View {
        Button(action: {
            if inviteSentSuccessfully {
                resetForm()
            } else {
                saveCrewMember()
            }
        }) {
            Text(isSaving ? "Saving..." : (inviteSentSuccessfully ? "Add More Crew" : "Send Invite"))
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.accentColor)
        .foregroundColor(.white)
        .cornerRadius(12)
        .padding(.top, 24)
        .disabled(isSaving || (!inviteSentSuccessfully && (newCrewName.isEmpty || newCrewEmail.isEmpty || selectedRoles.isEmpty)))
    }
    
    private var dateRangePicker: some View {
        VStack(alignment: .leading) {
             Text("Temporary Access Range")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                CustomDateField(date: $startDate)
                Text("to")
                CustomDateField(date: $endDate)
            }
        }
        .padding(.top)
    }
    
    private func invitationCodeView(code: String) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading) {
                Text("Invite code for new user:").font(.headline)
                Text(code).font(.largeTitle.bold()).foregroundColor(.green)
                Text("User can enter this code on the sign in screen.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: { copyInviteDetails(code: code) }) {
                VStack(spacing: 2) {
                    Image(systemName: "doc.on.doc")
                        .font(.body)
                    Text("Copy Invite Details")
                        .font(.caption2)
                }
            }
            .buttonStyle(.plain)
            .padding(8)
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }

    private var inputFields: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                CustomTextField(placeholder: "Name", text: $newCrewName)
                HStack(spacing: 8) {
                    CustomTextField(placeholder: "Email", text: $newCrewEmail)
                    switch emailValidationState {
                    case .checking: ProgressView().scaleEffect(0.5)
                    case .valid: Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    case .invalid: Image(systemName: "person.badge.plus").foregroundColor(.orange)
                    case .info: Image(systemName: "info.circle").foregroundColor(.blue)
                    case .none: EmptyView().frame(width: 20)
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
                        VStack(alignment: .leading, spacing: 0) {
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
            
            Picker("Visibility", selection: $selectedVisibility) {
                ForEach(CrewVisibility.allCases, id: \.self) { visibility in
                    Text(visibility.rawValue.capitalized).tag(visibility)
                }
            }.pickerStyle(.segmented)
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
                        if let id = foundID {
                            self.foundUserId = id
                            self.emailValidationState = .valid
                        } else {
                            self.emailValidationState = .invalid
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async { self.emailValidationState = .none }
            }
        }
    }
    
    private func copyInviteDetails(code: String) {
        let tourName = appState.tours.first { $0.id == tourID }?.tourName ?? "the tour"
        let inviteString = """
        Join \(tourName) by downloading Encore at:
        https://en-co.re

        Your joining code is \(code)
        """
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(inviteString, forType: .string)
    }

    private func saveCrewMember() {
        guard !newCrewName.isEmpty, !selectedRoles.isEmpty, !newCrewEmail.isEmpty,
              let ownerId = appState.userID,
              let currentTour = appState.tours.first(where: { $0.id == tourID })
        else { return }
        
        isSaving = true
        let db = Firestore.firestore()

        let newCrewMember = TourCrew(
            tourId: self.tourID,
            userId: self.foundUserId,
            contactId: nil,
            name: newCrewName.trimmingCharacters(in: .whitespaces),
            email: newCrewEmail.trimmingCharacters(in: .whitespaces).lowercased(),
            roles: selectedRoles,
            visibility: selectedVisibility,
            status: foundUserId != nil ? .pending : .invited,
            invitationCode: nil,
            startDate: selectedVisibility == .temporary ? Timestamp(date: startDate) : nil,
            endDate: selectedVisibility == .temporary ? Timestamp(date: endDate) : nil,
            invitedBy: ownerId
        )

        var ref: DocumentReference? = nil
        do {
            ref = try db.collection("tourCrew").addDocument(from: newCrewMember) { error in
                if let error = error {
                    print("❌ Error saving new crew member: \(error.localizedDescription)")
                    self.isSaving = false
                    return
                }
                
                guard let crewDocId = ref?.documentID else {
                    self.isSaving = false
                    return
                }

                if let recipientId = self.foundUserId {
                    FirebaseUserService.shared.createInvitationNotification(
                        for: currentTour,
                        recipientId: recipientId,
                        inviterId: ownerId,
                        inviterName: Auth.auth().currentUser?.displayName ?? "An Encore User",
                        crewDocId: crewDocId,
                        roles: self.selectedRoles
                    )
                    self.inviteSentSuccessfully = true
                } else {
                    FirebaseUserService.shared.createInvitation(for: crewDocId, tourId: self.tourID, inviterId: ownerId) { code in
                        if let code = code {
                            db.collection("tourCrew").document(crewDocId).updateData(["invitationCode": code])
                            self.generatedCode = code
                        }
                        self.inviteSentSuccessfully = true
                    }
                }
                self.isSaving = false
            }
        } catch {
            print("❌ Error adding document: \(error.localizedDescription)")
            isSaving = false
        }
    }
    
    private func resetForm() {
        newCrewName = ""
        newCrewEmail = ""
        roleInput = ""
        selectedRoles.removeAll()
        showRoleSuggestions = false
        selectedVisibility = .full
        startDate = Date()
        endDate = Date()
        foundUserId = nil
        generatedCode = nil
        isSaving = false
        inviteSentSuccessfully = false
        emailValidationState = .none
        emailCheckTask?.cancel()
    }
}
