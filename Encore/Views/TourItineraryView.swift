import SwiftUI
import FirebaseFirestore

struct TourItineraryView: View {
    @StateObject private var viewModel: ItineraryViewModel
    @EnvironmentObject var appState: AppState
    
    let tour: Tour
    
    // The view is now initialized with a Tour and creates its own ViewModel
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
                SectionHeader(title: "Itinerary", onAdd: { viewModel.isAddingItem = true })
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                #if os(iOS)
                    .padding(.top, 8)
                #endif
                
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
            // The onSave closure is no longer needed as the view updates automatically.
            ItineraryItemEditView(item: .constant(item), onSave: {})
        }
        .sheet(isPresented: $viewModel.isAddingItem) {
            // The onSave closure is no longer needed as the view updates automatically.
            ItineraryItemAddView(
                tourID: tour.id ?? "",
                userID: tour.ownerId,
                onSave: {},
                showForTimezone: viewModel.showForSelectedDate
            )
        }
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
}
