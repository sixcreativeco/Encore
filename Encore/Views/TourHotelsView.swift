import SwiftUI
import FirebaseFirestore

struct TourHotelsView: View {
    var tourID: String
    
    @State private var hotels: [Hotel] = []
    @State private var showAddHotel = false
    @State private var hotelListener: ListenerRegistration? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Hotels", onAdd: { showAddHotel = true })

            if hotels.isEmpty {
                Text("No hotels booked for this tour yet.")
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .padding()
                    .background(Color.black.opacity(0.15))
                    .cornerRadius(12)
            } else {
                hotelList
            }
        }
        .onAppear(perform: setupListener)
        .onDisappear { hotelListener?.remove() }
        .sheet(isPresented: $showAddHotel) {
             if let tour = appState.tours.first(where: { $0.id == tourID }) {
                AddHotelView(tour: tour, onHotelAdded: {})
             }
        }
    }
    
    @EnvironmentObject var appState: AppState

    private var hotelList: some View {
        VStack(spacing: 12) {
            ForEach(hotels) { hotel in
                HotelCardView(hotel: hotel)
            }
        }
    }

    private func setupListener() {
        hotelListener?.remove()
        hotelListener = FirebaseHotelService.shared.addHotelsListener(forTour: tourID) { loadedHotels in
            self.hotels = loadedHotels
        }
    }
}

// MARK: - HotelCardView (Redesigned)

struct HotelCardView: View {
    let hotel: Hotel
    @State private var isExpanded = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM"
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "bed.double.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(hotel.name).font(.headline)
                    Text(hotel.city).font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { withAnimation(.easeInOut) { isExpanded.toggle() }}) {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }.buttonStyle(.plain)
            }
            .padding()

            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // Dates & Booking Ref
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Check-in").font(.caption).foregroundColor(.secondary)
                                Text("\(dateFormatter.string(from: hotel.checkInDate.dateValue())) \(timeFormatter.string(from: hotel.checkInDate.dateValue()))")
                                    .fontWeight(.medium)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Check-out").font(.caption).foregroundColor(.secondary)
                                Text("\(dateFormatter.string(from: hotel.checkOutDate.dateValue())) \(timeFormatter.string(from: hotel.checkOutDate.dateValue()))")
                                    .fontWeight(.medium)
                            }
                        }
                         if let ref = hotel.bookingReference, !ref.isEmpty {
                            Text("Booking Ref: \(ref)").font(.caption)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Rooms & Guests
                    if !hotel.rooms.isEmpty {
                         Divider()
                        Text("Rooms").font(.headline).padding(.horizontal)
                        ForEach(hotel.rooms) { room in
                            VStack(alignment: .leading, spacing: 4) {
                                if let roomNum = room.roomNumber, !roomNum.isEmpty {
                                    Text("Room \(roomNum)").font(.subheadline.bold())
                                }
                                ForEach(room.guests) { guest in
                                    Label(guest.name, systemImage: "person")
                                        .font(.subheadline)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                    }
                }
                .padding(.bottom)
            }
        }
        .background(Color.black.opacity(0.15))
        .cornerRadius(12)
    }
}
