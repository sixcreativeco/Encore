import SwiftUI

struct DatabaseView: View {
    let userID: String

    enum SectionType: String, CaseIterable {
        case contacts = "Contacts"
        case venues = "Venues"
        case hotels = "Hotels"
    }

    @State private var selectedSection: SectionType = .contacts
    @State private var searchText: String = ""
    @State private var selectedFilter: String = "All"
    @State private var sortField: String = ""
    @State private var sortAscending: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            customHeader
            searchAndFilterBar
            Divider()
            sectionContent
        }
        .padding()
    }

    private var customHeader: some View {
        HStack(spacing: 24) {
            ForEach(SectionType.allCases, id: \.self) { section in
                Button(action: { selectedSection = section }) {
                    Text(section.rawValue)
                        .font(.largeTitle.bold())
                        .foregroundColor(selectedSection == section ? .primary : .gray)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.bottom, 10)
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
        case .venues:
            VenuesSection(userID: userID, searchText: searchText, selectedFilter: selectedFilter, sortField: $sortField, sortAscending: $sortAscending)
        case .hotels:
            HotelsSection(userID: userID, searchText: searchText, selectedFilter: selectedFilter, sortField: $sortField, sortAscending: $sortAscending)
        }
    }

    private func currentFilters() -> [String] {
        switch selectedSection {
        case .contacts: return ContactFilter.allCases.map { $0.displayName }
        case .venues: return VenueFilter.allCases.map { $0.displayName }
        case .hotels: return HotelFilter.allCases.map { $0.displayName }
        }
    }
}
