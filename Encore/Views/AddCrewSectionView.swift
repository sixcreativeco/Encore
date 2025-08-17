import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import AppKit

// --- A simple networking helper to call your new API endpoints ---
struct UserAPI {
    // This function now calls your secure backend endpoint
    static func checkUserExists(byEmail email: String) async throws -> String? {
        print("[UserAPI] 📞 Calling backend to check email: \(email)")
        guard let url = URL(string: "https://encoretickets.vercel.app/api/check-user-by-email") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["email": email])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        if let exists = json?["exists"] as? Bool, exists {
            let userId = json?["userId"] as? String
            print("[UserAPI] ✅ Backend response: User exists with ID: \(userId ?? "N/A")")
            return userId
        } else {
            print("[UserAPI] ✅ Backend response: User does not exist.")
            return nil
        }
    }
}

struct InvitationAPI {
    static func createInvitation(crewDocId: String, tourId: String, inviterId: String) async throws -> String? {
        guard let url = URL(string: "https://encoretickets.vercel.app/api/create-invitation") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "crewDocId": crewDocId,
            "tourId": tourId,
            "inviterId": inviterId
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        return json?["code"] as? String
    }
}


struct AddCrewSectionView: View {
    let tour: Tour
    var showCrewList: Bool = true
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
        "Lead Artist", "Support Artist", "DJ", "Dancer", "Guest Performer", "Musician", "Content", "Tour Manager", "Artist Manager", "Road Manager", "Assistant Manager", "Tour Accountant", "Advance Coordinator", "Production Manager", "Stage Manager", "Lighting", "Sound", "Audio Tech", "Video", "Playback Operator", "Backline Tech", "Rigger", "SFX", "Driver", "Transport Coordinator", "Logistics", "Fly Tech", "Local Runner", "Security", "Assistant", "Stylist", "Hair and Makeup", "Catering", "Merch Manager", "Wellness", "PA", "Childcare", "Label Rep", "Marketing", "Street Team", "Promoter Rep", "Merch Staff", "Translator", "Drone Op", "Content Creator", "Custom"
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
                        case .checking: ProgressView().scaleEffect(0.5)
                        case .valid: Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        case .invalid: Image(systemName: "person.badge.plus").foregroundColor(.orange)
                        case .none: EmptyView().frame(width: 20)
                        }
                    }
                }
                .onChange(of: newCrewEmail) { _, newValue in
                    checkEmailWithDebounce(email: newValue)
                }

                // Role input section... (unchanged)
                VStack(spacing: 4) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(selectedRoles, id: \.self) { role in
                                HStack(spacing: 6) {
                                    Text(role).font(.subheadline)
                                    Button(action: { selectedRoles.removeAll { $0 == role } }) {
                                        Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                                    }.buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.black.opacity(0.2)).cornerRadius(6)
                            }
                            TextField("Type a role", text: $roleInput)
                                .textFieldStyle(PlainTextFieldStyle()).frame(minWidth: 100)
                                .onChange(of: roleInput) { _, value in showRoleSuggestions = !value.isEmpty }
                                .onSubmit { addCustomRole() }
                        }
                        .padding(.horizontal, 8).padding(.vertical, 6)
                    }
                    .frame(height: 42).background(Color.black.opacity(0.15)).cornerRadius(8)
                    ZStack {
                        if showRoleSuggestions && !filteredRoles.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(filteredRoles.prefix(5), id: \.self) { suggestion in
                                    Button(action: {
                                        selectedRoles.append(suggestion)
                                        roleInput = ""
                                        showRoleSuggestions = false
                                    }) { Text(suggestion).frame(maxWidth: .infinity, alignment: .leading).padding(8) }.buttonStyle(.plain)
                                }
                            }
                            .background(Color(NSColor.windowBackgroundColor)).cornerRadius(6).shadow(radius: 1).padding(.top, 4)
                        }
                    }
                }
                
                Button(action: { Task { await saveCrewMember() } }) {
                    HStack {
                        if isSaving { ProgressView().scaleEffect(0.8).frame(width: 15, height: 15) }
                        else { Image(systemName: "plus") }
                        Text(isSaving ? "Inviting..." : "Add & Invite Crew Member")
                    }
                }
                .disabled(isSaving || !isFormValid)
                .font(.subheadline)
            }
            .padding(.top)

            if showCrewList {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(crewMembers) { member in
                        crewMemberCard(member)
                    }
                }
            }
        }
        .padding(.top, 12)
        .onAppear { loadCrew() }
        .onDisappear { listener?.remove() }
    }
    
    // crewMemberCard and copyInviteDetails... (unchanged)
    @ViewBuilder
    private func crewMemberCard(_ member: TourCrew) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name).font(.subheadline.bold())
                if let email = member.email, !email.isEmpty { Text(email).font(.caption).foregroundColor(.secondary) }
                Text(member.roles.joined(separator: ", ")).font(.caption)
            }
            Spacer()
            switch member.status {
            case .pending: Text("Invite Sent").font(.caption.bold()).foregroundColor(.blue)
            case .accepted: HStack(spacing: 4) { Image(systemName: "checkmark.circle.fill"); Text("Accepted") }.font(.caption.bold()).foregroundColor(.green)
            case .invited:
                if let code = member.invitationCode {
                    HStack(spacing: 8) {
                        Text(code).font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(.orange)
                        Button(action: { copyInviteDetails(code: code) }) { Image(systemName: "doc.on.doc") }.buttonStyle(.plain)
                    }
                }
            }
        }.padding(12).background(Color.black.opacity(0.15)).cornerRadius(8)
    }
    
    private func copyInviteDetails(code: String) {
        let tourName = appState.tours.first { $0.id == tour.id }?.tourName ?? "the tour"
        let inviteString = "Join \(tourName) by downloading Encore at:\nhttps://en-co.re\n\nYour joining code is \(code)"
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
                
                // --- THIS IS THE FIX ---
                // Call the new secure API endpoint instead of the old FirebaseUserService
                let foundID = try await UserAPI.checkUserExists(byEmail: trimmedEmail)
                
                await MainActor.run {
                    self.foundUserId = foundID
                    self.emailValidationState = (foundID != nil) ? .valid : .invalid
                }
                // --- END OF FIX ---
                
            } catch {
                await MainActor.run { self.emailValidationState = .none }
            }
        }
    }

    private func addCustomRole() {
        let trimmedRole = roleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRole.isEmpty else { return }
        if !roleOptions.contains(trimmedRole) { roleOptions.append(trimmedRole) }
        selectedRoles.append(trimmedRole)
        roleInput = ""
        showRoleSuggestions = false
    }

    private func saveCrewMember() async {
        print("[Debug] 1. saveCrewMember called.")
        guard isFormValid, let ownerId = appState.userID, let tourID = tour.id else {
            print("[Debug] ❌ saveCrewMember failed validation.")
            return
        }
        
        await MainActor.run { isSaving = true }
        
        let crewToSave = TourCrew(
            tourId: tourID, userId: foundUserId, contactId: nil, name: newCrewName.trimmingCharacters(in: .whitespaces),
            email: newCrewEmail.trimmingCharacters(in: .whitespaces).lowercased(), roles: selectedRoles, visibility: .full,
            status: foundUserId != nil ? .pending : .invited, invitationCode: nil, startDate: nil, endDate: nil, invitedBy: ownerId
        )

        do {
            let db = Firestore.firestore()
            let ref = try await db.collection("tourCrew").addDocument(from: crewToSave)
            print("[Debug] 2. Successfully saved new crew document: \(ref.documentID)")
            
            if let recipientId = foundUserId {
                print("[Debug] 3a. User exists. Sending notification to \(recipientId).")
                let tourRef = db.collection("tours").document(tourID)
                try await tourRef.setData(["members": [recipientId: "crew"]], merge: true)
                
                FirebaseUserService.shared.createInvitationNotification(
                    for: tour, recipientId: recipientId, inviterId: ownerId,
                    inviterName: Auth.auth().currentUser?.displayName ?? "An Encore User", crewDocId: ref.documentID, roles: selectedRoles
                )
            } else {
                print("[Debug] 3b. New user. Requesting invitation code from server.")
                let code = try await InvitationAPI.createInvitation(
                    crewDocId: ref.documentID, tourId: tour.id ?? "", inviterId: ownerId
                )
                
                if let code = code {
                    print("[Debug] 4. Received code '\(code)' from server. Updating document.")
                    try await ref.updateData(["invitationCode": code])
                    print("[Debug] 5. Document updated successfully.")
                } else {
                    print("[Debug] ❌ Failed to get an invitation code from the server.")
                }
            }
            
            await MainActor.run {
                print("[Debug] 6. Operation complete. Resetting form.")
                resetForm()
            }
            
        } catch {
            print("❌ ERROR in saveCrewMember: \(error.localizedDescription)")
            await MainActor.run { isSaving = false }
        }
    }
    
    private func resetForm() {
        newCrewName = ""; newCrewEmail = ""; roleInput = ""
        selectedRoles.removeAll(); showRoleSuggestions = false; foundUserId = nil
        emailValidationState = .none; emailCheckTask?.cancel(); isSaving = false
    }
    
    private func loadCrew() {
        guard let tourID = tour.id else { return }
        listener?.remove()
        let db = Firestore.firestore()
        
        listener = db.collection("tourCrew").whereField("tourId", isEqualTo: tourID)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self.crewMembers = documents.compactMap { try? $0.data(as: TourCrew.self) }
            }
    }
}
