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
    @State private var selectedFilter: String = "All"
    @State private var sortField: String = ""
    @State private var sortAscending: Bool = true
    @State private var activeSheet: ActiveSheet?
    @State private var contactsKey = UUID()

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
                            .foregroundColor(selectedSection == section ? .primary : .gray)
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
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 10)
            }
        }
    }

    private var searchAndFilterBar: some View {
        HStack {
            StyledInputField(placeholder: "Search...", text: $searchText)
                .frame(width: 300)
            Spacer()
            Text("Filter").foregroundColor(.gray)
            Picker("", selection: $selectedFilter) {
                ForEach(currentFilters(), id: \.self) { filter in
                    Text(filter).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 400)
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .contacts:
            ContactsSection(userID: userID, searchText: searchText, selectedFilter: selectedFilter, sortField: $sortField, sortAscending: $sortAscending)
                .id(contactsKey)
        case .venues:
            VenuesSection(userID: userID, searchText: searchText, selectedFilter: selectedFilter, sortField: $sortField, sortAscending: $sortAscending)
        case .hotels:
            HotelsSection(userID: userID, searchText: searchText, selectedFilter: selectedFilter, sortField: $sortField, sortAscending: $sortAscending)
        case .customers:
            CustomersSection(userID: userID, searchText: searchText, selectedFilter: selectedFilter, sortField: $sortField, sortAscending: $sortAscending)
        }
    }

    private func currentFilters() -> [String] {
        switch selectedSection {
        case .contacts: return ContactFilter.allCases.map { $0.displayName }
        case .venues: return VenueFilter.allCases.map { $0.displayName }
        case .hotels: return HotelFilter.allCases.map { $0.displayName }
        case .customers: return ["All"]
        }
    }
}
