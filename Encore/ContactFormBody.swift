import SwiftUI
import FirebaseFirestore
import Kingfisher

struct ContactFormBody: View {
    @Binding var contact: Contact
    var isDisabled: Bool

    // MARK: - State
    @State private var roleInput: String = ""
    @State private var newLoyaltyAirline: String = ""
    @State private var newLoyaltyNumber: String = ""
    
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
            personalDetailsSection
            travelDetailsSection
            loyaltyProgramSection
            documentsSection
            emergencyDetailsSection
        }
        .disabled(isDisabled)
    }
    
    // MARK: - Subviews
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                if let location = contact.location, !location.isEmpty {
                    Label(location, systemImage: "location.fill")
                        .foregroundColor(.secondary)
                } else {
                    StyledInputField(placeholder: "Location (e.g. Auckland, NZ)", text: optionalStringBinding(for: $contact.location))
                }
                
                StyledInputField(placeholder: "Email", text: optionalStringBinding(for: $contact.email))
                StyledInputField(placeholder: "Phone Number", text: optionalStringBinding(for: $contact.phone))
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(nsColor: .controlBackgroundColor))

                KFImage(URL(string: contact.profileImageURL ?? ""))
                    .placeholder {
                        Image(systemName: "person.crop.rectangle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .frame(width: 120, height: 150) // 4:5 aspect ratio
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // --- FIX IS HERE ---
    // The layout has been corrected to ensure pills and the input field do not overlap.
    private var rolesInputView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Roles").font(.subheadline).foregroundColor(.gray)
            
            // This VStack now properly contains the wrapping pills and the input field separately.
            VStack(alignment: .leading, spacing: 45) {
                if !contact.roles.isEmpty {
                    WrapView(items: contact.roles) { role in
                        HStack(spacing: 4) {
                            Text(role)
                            Button(action: { contact.roles.removeAll { $0 == role } }) {
                                Image(systemName: "xmark")
                            }
                            .buttonStyle(.plain)
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.2))
                        .clipShape(Capsule())
                    }
                }
                
                StyledInputField(placeholder: "Add Role...", text: $roleInput)
                    .onSubmit(addCustomRole)
            }

            if !filteredRoles.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(filteredRoles.prefix(5), id: \.self) { suggestion in
                            Button(action: {
                                contact.roles.append(suggestion)
                                roleInput = ""
                            }) {
                                Text(suggestion)
                                    .font(.caption)
                                    .padding(.horizontal, 8).padding(.vertical, 4).background(Color.gray.opacity(0.2)).cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
    // --- END OF FIX ---
    
    private var personalDetailsSection: some View {
        HStack(alignment: .lastTextBaseline, spacing: 16) {
            CustomDateInputView(label: "Date of Birth", date: timestampBinding(for: $contact.dateOfBirth))
            VStack(alignment: .leading, spacing: 4) {
                Text("Country of Birth").font(.subheadline).foregroundColor(.gray)
                StyledInputField(placeholder: "Country", text: optionalStringBinding(for: $contact.countryOfBirth))
            }
        }
    }

    private var travelDetailsSection: some View {
        CollapsibleSection(title: "Travel Details", icon: "airplane") {
            VStack(alignment: .leading, spacing: 16) {
                StyledInputField(placeholder: "Passport Number", text: passportStringBinding(for: \.passportNumber))
                HStack(spacing: 16) {
                    CustomDateInputView(label: "Issued Date", date: passportTimestampBinding(for: \.issuedDate))
                    CustomDateInputView(label: "Expiry Date", date: passportTimestampBinding(for: \.expiryDate))
                }
                StyledInputField(placeholder: "Issuing Country", text: passportStringBinding(for: \.issuingCountry))
                StyledInputField(placeholder: "Home Airport (e.g. AKL)", text: optionalStringBinding(for: $contact.notes)) // Using notes field for now
            }
        }
    }
    
    private var loyaltyProgramSection: some View {
        CollapsibleSection(title: "Loyalty Program", icon: "star.fill") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach($contact.loyaltyPrograms.withDefault([])) { $program in
                    HStack {
                        Text(program.airline).fontWeight(.bold)
                        Text(program.accountNumber).foregroundColor(.secondary)
                        Spacer()
                        Button(action: { contact.loyaltyPrograms?.removeAll { $0.id == program.id }}) {
                            Image(systemName: "xmark.circle.fill")
                        }.buttonStyle(.plain)
                    }
                }
                
                HStack {
                    StyledInputField(placeholder: "Type Airline", text: $newLoyaltyAirline)
                    StyledInputField(placeholder: "Enter Membership", text: $newLoyaltyNumber)
                    Button("Add Membership") {
                        let trimmedAirline = newLoyaltyAirline.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedNumber = newLoyaltyNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedAirline.isEmpty, !trimmedNumber.isEmpty else { return }
                        let newProgram = LoyaltyProgram(airline: trimmedAirline, accountNumber: trimmedNumber)
                        contact.loyaltyPrograms = (contact.loyaltyPrograms ?? []) + [newProgram]
                        newLoyaltyAirline = ""
                        newLoyaltyNumber = ""
                    }
                }
            }
        }
    }
    
    private var documentsSection: some View {
        CollapsibleSection(title: "Documents", icon: "doc.text.fill") {
            VStack(alignment: .leading) {
                Text("Document uploads coming soon.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }

    private var emergencyDetailsSection: some View {
        CollapsibleSection(title: "Emergency Details", icon: "staroflife.fill") {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    StyledInputField(placeholder: "Emergency Contact", text: emergencyBinding(for: \.name))
                    StyledInputField(placeholder: "Phone Number", text: emergencyBinding(for: \.phone))
                }
                StyledInputField(placeholder: "Allergies", text: optionalStringBinding(for: $contact.allergies))
                StyledInputField(placeholder: "Medications", text: optionalStringBinding(for: $contact.medications))
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
    private func optionalStringBinding(for binding: Binding<String?>) -> Binding<String> {
        Binding<String>( get: { binding.wrappedValue ?? "" }, set: { binding.wrappedValue = $0.isEmpty ? nil : $0 } )
    }
    
    private func timestampBinding(for optionalTimestamp: Binding<Timestamp?>) -> Binding<Date> {
        Binding<Date>(
            get: { optionalTimestamp.wrappedValue?.dateValue() ?? Date() },
            set: { optionalTimestamp.wrappedValue = Timestamp(date: $0) }
        )
    }
    
    private func passportStringBinding(for keyPath: WritableKeyPath<PassportInfo, String>) -> Binding<String> {
        Binding<String>(
            get: { self.contact.passport?[keyPath: keyPath] ?? "" },
            set: { newValue in
                if self.contact.passport == nil {
                    self.contact.passport = PassportInfo(passportNumber: "", issuedDate: Timestamp(date: Date()), expiryDate: Timestamp(date: Date()), issuingCountry: "")
                }
                self.contact.passport?[keyPath: keyPath] = newValue
            }
        )
    }
    
    private func passportTimestampBinding(for keyPath: WritableKeyPath<PassportInfo, Timestamp>) -> Binding<Date> {
        Binding<Date>(
            get: {
                if let date = self.contact.passport?[keyPath: keyPath].dateValue() {
                    return date
                }
                return Date()
            },
            set: { newValue in
                if self.contact.passport == nil {
                    self.contact.passport = PassportInfo(passportNumber: "", issuedDate: Timestamp(date: Date()), expiryDate: Timestamp(date: Date()), issuingCountry: "")
                }
                self.contact.passport?[keyPath: keyPath] = Timestamp(date: newValue)
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

extension Binding {
    func withDefault<T>(_ defaultValue: T) -> Binding<T> where Value == T? {
        Binding<T>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 }
        )
    }
}

private struct CollapsibleSection<Content: View>: View {
    let title: String
    let icon: String
    @State private var isExpanded: Bool
    let content: () -> Content
    
    init(title: String, icon: String, isInitiallyExpanded: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self._isExpanded = State(initialValue: isInitiallyExpanded)
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: icon).foregroundColor(.accentColor)
                    Text(title).font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right").rotationEffect(.degrees(isExpanded ? 90 : 0))
                }.foregroundColor(.primary)
            }.buttonStyle(.plain)
            
            if isExpanded {
                content().padding(.top, 8)
            }
        }
    }
}
