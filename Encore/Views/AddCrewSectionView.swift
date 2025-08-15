import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import AppKit

struct AddCrewSectionView: View {
    // This view now accepts the entire Tour object
    let tour: Tour
    @EnvironmentObject var appState: AppState

    @State private var crewMembers: [TourCrew] = []
    @State private var newCrewName: String = ""
    @State private var newCrewEmail: String = ""
    @State private var roleInput: String = ""
    @State private var selectedRoles: [String] = []
    @State private var showRoleSuggestions: Bool = false
    
    @State private var foundUserId: String?
    @State private var isSaving = false
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
    
    private var isFormValid: Bool {
        !newCrewName.isEmpty && !newCrewEmail.isEmpty && !selectedRoles.isEmpty
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
                        case .invalid:
                             Image(systemName: "person.badge.plus").foregroundColor(.orange)
                        case .none:
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

                Button(action: { Task { await saveCrewMember() } }) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 15, height: 15)
                        } else {
                            Image(systemName: "plus")
                        }
                        Text(isSaving ? "Inviting..." : "Add & Invite Crew Member")
                    }
                }
                .disabled(isSaving || !isFormValid)
                .font(.subheadline)
            }
            .padding(.top)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(crewMembers) { member in
                    crewMemberCard(member)
                }
            }
        }
        .padding(.top, 12)
        .onAppear { loadCrew() }
        .onDisappear { listener?.remove() }
    }
    
    @ViewBuilder
    private func crewMemberCard(_ member: TourCrew) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name).font(.subheadline.bold())
                if let email = member.email, !email.isEmpty {
                    Text(email).font(.caption).foregroundColor(.secondary)
                }
                Text(member.roles.joined(separator: ", ")).font(.caption)
            }
            
            Spacer()
            
            switch member.status {
            case .pending:
                Text("Invite Sent")
                    .font(.caption.bold()).foregroundColor(.blue)
            case .accepted:
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Accepted")
                }
                .font(.caption.bold()).foregroundColor(.green)
            case .invited:
                if let code = member.invitationCode {
                    HStack(spacing: 8) {
                        Text(code)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                        
                        Button(action: { copyInviteDetails(code: code) }) {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.15))
        .cornerRadius(8)
    }
    
    private func copyInviteDetails(code: String) {
        let tourName = appState.tours.first { $0.id == tour.id }?.tourName ?? "the tour"
        let inviteString = """
        Join \(tourName) by downloading Encore at:
        https://en-co.re

        Your joining code is \(code)
        """
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(inviteString, forType: .string)
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

    private func saveCrewMember() async {
        guard isFormValid, let ownerId = appState.userID, let tourID = tour.id else {
            return
        }
        
        await MainActor.run { isSaving = true }
        
        let crewToSave = TourCrew(
            tourId: tourID,
            userId: foundUserId,
            contactId: nil,
            name: newCrewName.trimmingCharacters(in: .whitespaces),
            email: newCrewEmail.trimmingCharacters(in: .whitespaces).lowercased(),
            roles: selectedRoles,
            visibility: .full,
            status: foundUserId != nil ? .pending : .invited,
            invitationCode: nil,
            startDate: nil,
            endDate: nil,
            invitedBy: ownerId
        )

        do {
            let db = Firestore.firestore()
            let ref = try await db.collection("tourCrew").addDocument(from: crewToSave)
            
            if let recipientId = foundUserId {
                // --- FIX START ---
                // If the user already exists, add them to the tour's members map immediately.
                let tourRef = db.collection("tours").document(tourID)
                try await tourRef.setData(["members": [recipientId: "crew"]], merge: true)
                // --- FIX END ---
                
                FirebaseUserService.shared.createInvitationNotification(
                    for: tour,
                    recipientId: recipientId,
                    inviterId: ownerId,
                    inviterName: Auth.auth().currentUser?.displayName ?? "An Encore User",
                    crewDocId: ref.documentID,
                    roles: selectedRoles
                )
            } else {
                let code = await withCheckedContinuation { continuation in
                    FirebaseUserService.shared.createInvitation(for: ref.documentID, tourId: tour.id ?? "", inviterId: ownerId) { code in
                        continuation.resume(returning: code)
                    }
                }
                if let code = code {
                    try await ref.updateData(["invitationCode": code])
                }
            }
            
            await MainActor.run {
                resetForm()
            }
            
        } catch {
            print("❌ ERROR in saveCrewMember: \(error.localizedDescription)")
            await MainActor.run {
                isSaving = false
            }
        }
    }
    
    private func resetForm() {
        newCrewName = ""
        newCrewEmail = ""
        roleInput = ""
        selectedRoles.removeAll()
        showRoleSuggestions = false
        foundUserId = nil
        emailValidationState = .none
        emailCheckTask?.cancel()
        isSaving = false
    }
    
    private func loadCrew() {
        guard let tourID = tour.id else { return }
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
