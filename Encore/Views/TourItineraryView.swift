import SwiftUI
import FirebaseFirestore

struct TourItineraryView: View {
    var tour: Tour
    @EnvironmentObject var appState: AppState

    @State private var allItems: [ItineraryItem] = []
    @State private var availableDates: [Date] = []
    @State private var selectedDate: Date? = nil
    
    @State private var itemToEdit: ItineraryItem?
    @State private var expandedItemID: String? = nil
    @State private var listeners: [ListenerRegistration] = []
    @State private var isAddingItem = false

    let calendar = Calendar.current
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                let itemsForSelectedDate = allItems.filter {
                    calendar.isDate($0.timeUTC.dateValue(), inSameDayAs: selectedDate ?? Date())
                }
                if itemsForSelectedDate.isEmpty {
                    Text("No items for this date.").foregroundColor(.gray).padding(.top, 50)
                } else {
                    ForEach(itemsForSelectedDate.sorted(by: { $0.timeUTC.dateValue() < $1.timeUTC.dateValue() })) { item in
                        ItineraryItemCard(item: item, isExpanded: expandedItemID == item.id, onExpandToggle: { toggleExpanded(item) }, onEdit: { self.itemToEdit = item }, onDelete: { deleteItem(item) })
                    }
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: "Itinerary", onAdd: { isAddingItem = true }).padding()
                if !availableDates.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(availableDates, id: \.self) { date in
                                Text(formattedDate(date))
                                    .fontWeight(calendar.isDate(date, inSameDayAs: selectedDate ?? Date()) ? .bold : .regular)
                                    .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate ?? Date()) ? .white : .primary)
                                    .padding(.vertical, 6).padding(.horizontal, 14)
                                    .background(calendar.isDate(date, inSameDayAs: selectedDate ?? Date()) ? Color.accentColor : Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                    .onTapGesture { selectedDate = date }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 50)
                    .padding(.bottom, 8)
                }
            }
            .background(.clear)
        }
        .onAppear { setupListeners() }
        .onDisappear { listeners.forEach { $0.remove() } }
        // FIX: This sheet modifier for editing is now fully implemented.
        .sheet(item: $itemToEdit) { item in
            // Find the index of the item to create a binding.
            // This is crucial for editing.
            if let index = allItems.firstIndex(where: { $0.id == item.id }) {
                ItineraryItemEditView(
                    item: $allItems[index],
                    onSave: {
                        let updatedItem = allItems[index]
                        guard let id = updatedItem.id else { return }
                        // Save the updated item to Firestore
                        try? Firestore.firestore().collection("itineraryItems").document(id).setData(from: updatedItem)
                    }
                )
            }
        }
        .sheet(isPresented: $isAddingItem) {
            ItineraryItemAddView(
                tourID: tour.id ?? "",
                userID: tour.ownerId,
                presetDate: selectedDate ?? Date(),
                onSave: {
                    // The listener handles the UI update automatically.
                }
            )
        }
    }

    private func toggleExpanded(_ item: ItineraryItem) {
        withAnimation {
            expandedItemID = (expandedItemID == item.id) ? nil : item.id
        }
    }

    private func deleteItem(_ item: ItineraryItem) {
        guard let itemID = item.id else { return }
        Firestore.firestore().collection("itineraryItems").document(itemID).delete()
    }
    
    private func setupListeners() {
        guard let tourID = tour.id else { return }
        
        self.availableDates = generateDateRange(from: tour.startDate.dateValue(), to: tour.endDate.dateValue())
        if selectedDate == nil {
            self.selectedDate = availableDates.first(where: { calendar.isDateInToday($0) }) ?? availableDates.first
        }
        
        let db = Firestore.firestore()
        self.listeners.forEach { $0.remove() }
        
        let listener = db.collection("itineraryItems")
            .whereField("tourId", isEqualTo: tourID)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self.allItems = documents.compactMap { try? $0.data(as: ItineraryItem.self) }
            }
        self.listeners = [listener]
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: date)
    }
    
    private func generateDateRange(from start: Date, to end: Date) -> [Date] {
        var dates: [Date] = []
        var current = start
        while calendar.isDate(current, inSameDayAs: end) || current < end {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return dates
    }
}
