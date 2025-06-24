import SwiftUI
import FirebaseFirestore

struct DatabaseView: View {
    let userID: String

    enum SectionType: String, CaseIterable {
        case contacts = "Contacts"
        case venues = "Venues"
        case hotels = "Hotels"
        case customers = "Customers"
    }

    private enum ActiveSheet: Identifiable {
        case addContact, addVenue, addHotel
        var id: Int { hashValue }
    }

    @State private var selectedSection: SectionType = .contacts
    @State private var searchText: String = ""
    @State private var sortField: String = ""
    @State private var sortAscending: Bool = true
    @State private var activeSheet: ActiveSheet?
    @State private var contactsKey = UUID()
    @State private var hideGuests: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerAndActions
            searchAndFilterBar
            Divider()
            sectionContent
        }
        .padding()
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addContact:
                ContactAddView {
                    self.contactsKey = UUID()
                }
            case .addVenue:
                DBAddVenueView()
            case .addHotel:
                DBAddHotelView()
            }
        }
    }

    private var headerAndActions: some View {
        HStack(alignment: .center) {
            HStack(spacing: 24) {
                ForEach(SectionType.allCases, id: \.self) { section in
                    Button(action: { selectedSection = section }) {
                        Text(section.rawValue)
                            .font(.largeTitle.bold())
                            .foregroundColor(selectedSection == section ? .primary : .primary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 10)
            
            Spacer()
            
            if selectedSection != .customers {
                Button(action: {
                    switch selectedSection {
                    case .contacts: activeSheet = .addContact
                    case .venues: activeSheet = .addVenue
                    case .hotels: activeSheet = .addHotel
                    case .customers: break
                    }
                }) {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .frame(width: 36, height: 36)
                .background(Color.black.opacity(0.15))
                .clipShape(Circle())
                .padding(.bottom, 10)
            }
        }
    }

    private var searchAndFilterBar: some View {
        HStack {
            StyledInputField(placeholder: "Search...", text: $searchText)
                .frame(width: 300)
            Spacer()
            if selectedSection == .contacts {
                Toggle("Hide Guests", isOn: $hideGuests)
                    .toggleStyle(.checkbox)
            }
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .contacts:
            ContactsSection(userID: userID, searchText: searchText, hideGuests: hideGuests, sortField: $sortField, sortAscending: $sortAscending)
                .id(contactsKey)
        case .venues:
            // The following sections do not need the hideGuests parameter
            let dummyBool = Binding.constant(false)
            let dummyString = Binding.constant("All")
             VenuesSection(userID: userID, searchText: searchText, selectedFilter: dummyString.wrappedValue, sortField: $sortField, sortAscending: $sortAscending)
        case .hotels:
            let dummyBool = Binding.constant(false)
            let dummyString = Binding.constant("All")
            HotelsSection(userID: userID, searchText: searchText, selectedFilter: dummyString.wrappedValue, sortField: $sortField, sortAscending: $sortAscending)
        case .customers:
             let dummyBool = Binding.constant(false)
            let dummyString = Binding.constant("All")
            CustomersSection(userID: userID, searchText: searchText, selectedFilter: dummyString.wrappedValue, sortField: $sortField, sortAscending: $sortAscending)
        }
    }
}
