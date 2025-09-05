import SwiftUI
import FirebaseFirestore

struct TourItineraryView: View {
    @StateObject private var viewModel: ItineraryViewModel
    @EnvironmentObject var appState: AppState
    
    let tour: Tour
    
    /// Defines the different sheets that can be presented.
    private enum ActiveSheet: Identifiable {
        case itineraryItem, flight, hotel
        var id: Int { self.hashValue }
    }
    
    @State private var activeSheet: ActiveSheet?
    @State private var isShowingAddOptionsPopover = false
    
    init(tour: Tour) {
        self.tour = tour
        _viewModel = StateObject(wrappedValue: ItineraryViewModel(tour: tour))
    }
    
    struct ItineraryDisplayGroup: Identifiable, Hashable {
        var id: DateComponents { dateComponents }
        let dateComponents: DateComponents
        var items: [ItineraryItem]
        var representativeDate: Date { items.first?.timeUTC.dateValue() ?? Date.distantPast }
        
        static func == (lhs: ItineraryDisplayGroup, rhs: ItineraryDisplayGroup) -> Bool {
            lhs.dateComponents == rhs.dateComponents
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(dateComponents)
        }
    }
        
    var body: some View {
        #if os(iOS)
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0/255, green: 58/255, blue: 83/255),
                    Color(red: 23/255, green: 17/255, blue: 17/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            mainContent.background(.clear)
        }
        #else
        mainContent.frame(height: 500)
        #endif
    }
        
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // --- THIS IS THE FIX ---
                // The SectionHeader has been replaced with a custom HStack,
                // and the .popover is now attached directly to the Button.
                HStack {
                    Text("Itinerary").font(.headline)
                    Spacer()
                    Button(action: { isShowingAddOptionsPopover = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $isShowingAddOptionsPopover, arrowEdge: .bottom) {
                        addOptionsPopover
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                #if os(iOS)
                .padding(.top, 8)
                #endif
                // --- END OF FIX ---
            
                if !viewModel.displayGroups.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.displayGroups) { group in
                                DateButtonView(
                                    group: group,
                                    shows: viewModel.shows,
                                    selectedGroupID: $viewModel.selectedGroupID
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 50)
                    .padding(.bottom, 12)
                }
            }
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.itemsForSelectedDate.isEmpty && !viewModel.displayGroups.isEmpty {
                        Text("No items scheduled for this date.")
                            .foregroundColor(.secondary)
                            .padding(.top, 50)
                    } else {
                        ForEach(viewModel.itemsForSelectedDate) { item in
                            ItineraryItemCard(
                                item: item,
                                locationHint: viewModel.showForSelectedDate?.city,
                                isExpanded: viewModel.expandedItemID == item.id,
                                onExpandToggle: { viewModel.toggleExpanded(item) },
                                onEdit: { viewModel.itemToEdit = item },
                                onDelete: { viewModel.deleteItem(item) }
                            )
                            .id(item.id)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .onDisappear {
            viewModel.cleanupListeners()
        }
        .sheet(item: $viewModel.itemToEdit) { item in
            ItineraryItemEditView(
                viewModel: viewModel,
                item: .constant(item),
                onSave: {}
            )
        }
        .sheet(item: $activeSheet) { sheetType in
            switch sheetType {
            case .itineraryItem:
                ItineraryItemAddView(viewModel: viewModel, onSave: {})
            case .flight:
                AddFlightView(tour: tour, onFlightAdded: {})
            case .hotel:
                AddHotelView(tour: tour, onHotelAdded: {})
            }
        }
    }
    
    /// The content view for the new popover menu.
    private var addOptionsPopover: some View {
        VStack(alignment: .leading, spacing: 0) {
            PopoverButton(title: "Add Event", icon: "calendar.badge.plus") {
                activeSheet = .itineraryItem
                isShowingAddOptionsPopover = false
            }
            Divider()
            PopoverButton(title: "Add Flight", icon: "airplane") {
                activeSheet = .flight
                isShowingAddOptionsPopover = false
            }
            Divider()
            PopoverButton(title: "Add Hotel", icon: "bed.double.fill") {
                activeSheet = .hotel
                isShowingAddOptionsPopover = false
            }
        }
        .padding(.vertical, 8)
        .frame(width: 200)
    }
        
    private struct DateButtonView: View {
        let group: ItineraryDisplayGroup
        let shows: [Show]
        @Binding var selectedGroupID: DateComponents?
        
        private var isSelected: Bool {
            selectedGroupID == group.id
        }
        
        private var city: String? {
            for item in group.items {
                if let showId = item.showId, let show = shows.first(where: { $0.id == showId }) {
                    return show.city
                }
            }
            return nil
        }
        
        var body: some View {
            VStack(spacing: 2) {
                Text(formattedDate(from: group.dateComponents))
                    .font(.system(size: 14, weight: .semibold))
                
                if let city = city, !city.isEmpty {
                    Text(city)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                }
            }
            .padding(.horizontal, 12)
            .frame(minWidth: 80, minHeight: 38)
            .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
            .cornerRadius(10)
            .onTapGesture {
                selectedGroupID = group.id
            }
        }
        
        private func formattedDate(from components: DateComponents) -> String {
            let calendar = Calendar.current
            guard let date = calendar.date(from: components) else { return "Invalid Date" }
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMM d"
            return formatter.string(from: date)
        }
    }
    
    /// A helper view for styling the buttons inside the popover.
    private struct PopoverButton: View {
        let title: String
        let icon: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Image(systemName: icon)
                        .font(.headline)
                        .frame(width: 25)
                    Text(title)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
