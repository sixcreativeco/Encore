import SwiftUI

struct ContactFormBody: View {
    @Binding var contact: ContactModel
    var isDisabled: Bool

    // MARK: - State
    @State private var isTravelDetailsExpanded: Bool = true
    @State private var isEmergencyDetailsExpanded: Bool = true
    @State private var roleInput: String = ""
    
    @State private var homeAirport: String = ""
    @State private var loyaltyAirline: String = ""
    @State private var loyaltyMembership: String = ""

    private let roleOptions: [String] = [
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
    
    private var filteredRoles: [String] {
        guard !roleInput.isEmpty else { return [] }
        return roleOptions.filter {
            $0.lowercased().contains(roleInput.lowercased()) && !contact.roles.contains($0)
        }
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerSection
            rolesInputView

            HStack(alignment: .lastTextBaseline, spacing: 16) {
                CustomDateInputView(label: "Date of Birth", date: binding(for: $contact.dateOfBirth))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Country of Birth").font(.subheadline).foregroundColor(.gray)
                    StyledInputField(placeholder: "Country of Birth", text: binding(for: $contact.countryOfBirth))
                }
            }

            CollapsibleSection(isExpanded: $isTravelDetailsExpanded, title: "Travel Details") {
                VStack(alignment: .leading, spacing: 16) {
                    StyledInputField(placeholder: "Passport Number", text: passportBinding(for: \.passportNumber))
                    HStack(spacing: 16) {
                        CustomDateInputView(label: "Issued Date", date: passportDateBinding(for: \.issuedDate))
                        CustomDateInputView(label: "Expiry Date", date: passportDateBinding(for: \.expiryDate))
                    }
                    StyledInputField(placeholder: "Issuing Country", text: passportBinding(for: \.issuingCountry))
                    StyledInputField(placeholder: "Home Airport", text: $homeAirport)

                    Text("Loyalty Program").font(.headline).padding(.top)
                    HStack(spacing: 16) {
                         StyledInputField(placeholder: "Type Airline", text: $loyaltyAirline)
                         StyledInputField(placeholder: "Enter Membership", text: $loyaltyMembership)
                    }
                    
                    Text("Documents").font(.headline).padding(.top)
                    Text("No documents uploaded.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            CollapsibleSection(isExpanded: $isEmergencyDetailsExpanded, title: "Emergency Details") {
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        StyledInputField(placeholder: "Emergency Contact", text: emergencyBinding(for: \.name))
                        StyledInputField(placeholder: "Phone Number", text: emergencyBinding(for: \.phone))
                    }
                    StyledInputField(placeholder: "Allergies", text: binding(for: $contact.allergies))
                    StyledInputField(placeholder: "Medications", text: binding(for: $contact.medications))
                }
            }
            .padding(.bottom)
        }
        .disabled(isDisabled)
    }
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(spacing: 12) {
                StyledInputField(placeholder: "Full Name*", text: $contact.name)
                StyledInputField(placeholder: "Location (e.g. Auckland, NZ)", text: binding(for: $contact.location))
                StyledInputField(placeholder: "Email", text: binding(for: $contact.email))
                StyledInputField(placeholder: "Phone Number", text: binding(for: $contact.phone))
            }
            
            Image(systemName: "person.crop.rectangle.fill")
                .font(.system(size: 100))
                .foregroundColor(.gray.opacity(0.5))
                .frame(width: 150)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
        }
    }
    
    private var rolesInputView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Roles*").font(.subheadline).foregroundColor(.gray)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(contact.roles, id: \.self) { role in
                        HStack(spacing: 6) {
                            Text(role).font(.subheadline)
                            Button(action: { contact.roles.removeAll { $0 == role } }) {
                                Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                            }.buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 4).background(Color.gray.opacity(0.2)).cornerRadius(6)
                    }
                    
                    TextField("Add Role", text: $roleInput)
                        .textFieldStyle(PlainTextFieldStyle())
                        .frame(minWidth: 150)
                        .onSubmit(addCustomRole)
                }
                .padding(8)
            }
            .frame(height: 44).background(Color(nsColor: .controlBackgroundColor)).cornerRadius(8)

            if !filteredRoles.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(filteredRoles.prefix(5).enumerated()), id: \.element) { index, suggestion in
                        Button(action: {
                            contact.roles.append(suggestion)
                            roleInput = ""
                        }) {
                            Text(suggestion)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)

                        if index < filteredRoles.prefix(5).count - 1 {
                            Divider()
                        }
                    }
                }
                .background(Color(nsColor: .windowBackgroundColor))
                .cornerRadius(8)
                .shadow(radius: 2)
            }
        }
    }
    
    private func addCustomRole() {
        let trimmedRole = roleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRole.isEmpty, !contact.roles.contains(trimmedRole) else {
            roleInput = ""
            return
        }
        contact.roles.append(trimmedRole)
        roleInput = ""
    }

    // MARK: - Bindings
    private func binding(for optionalString: Binding<String?>) -> Binding<String> {
        Binding<String>( get: { optionalString.wrappedValue ?? "" }, set: { optionalString.wrappedValue = $0.isEmpty ? nil : $0 } )
    }
    private func binding(for optionalDate: Binding<Date?>) -> Binding<Date> {
        Binding<Date>( get: { optionalDate.wrappedValue ?? Date() }, set: { optionalDate.wrappedValue = $0 } )
    }
    
    // FIXED: The binding logic is now more explicit to avoid compiler confusion.
    private func passportBinding(for keyPath: WritableKeyPath<PassportInfo, String>) -> Binding<String> {
        Binding<String>(
            get: { self.contact.passport?[keyPath: keyPath] ?? "" },
            set: { newValue in
                if self.contact.passport == nil {
                    self.contact.passport = PassportInfo(passportNumber: "", issuedDate: Date(), expiryDate: Date(), issuingCountry: "")
                }
                self.contact.passport?[keyPath: keyPath] = newValue
            }
        )
    }
    
    private func passportDateBinding(for keyPath: WritableKeyPath<PassportInfo, Date>) -> Binding<Date> {
        Binding<Date>(
            get: { self.contact.passport?[keyPath: keyPath] ?? Date() },
            set: { newValue in
                if self.contact.passport == nil {
                    self.contact.passport = PassportInfo(passportNumber: "", issuedDate: Date(), expiryDate: Date(), issuingCountry: "")
                }
                self.contact.passport?[keyPath: keyPath] = newValue
            }
        )
    }
    
    private func emergencyBinding(for keyPath: WritableKeyPath<EmergencyContact, String>) -> Binding<String> {
        Binding<String>(
            get: { self.contact.emergencyContact?[keyPath: keyPath] ?? "" },
            set: { newValue in
                if self.contact.emergencyContact == nil {
                    self.contact.emergencyContact = EmergencyContact(name: "", phone: "")
                }
                self.contact.emergencyContact?[keyPath: keyPath] = newValue
            }
        )
    }
}

private struct CollapsibleSection<Content: View>: View {
    @Binding var isExpanded: Bool
    let title: String
    let content: () -> Content
    var body: some View {
        VStack(alignment: .leading) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack {
                    Text(title).font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right").rotationEffect(.degrees(isExpanded ? 90 : 0))
                }.foregroundColor(.primary)
            }.buttonStyle(.plain)
            if isExpanded { content().padding(.top, 8) }
        }
    }
}
