import SwiftUI
import Combine
import FirebaseFirestore // Import for Timestamp

struct SignInDynamicContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var initialDate = Date()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundGradient
                auroraView(proxy: proxy)
                floatingShapes(proxy: proxy)
                
                TimelineView(.animation(minimumInterval: 0.016, paused: false)) { context in
                    let elapsedTime = context.date.timeIntervalSince(initialDate)
                    cardStack(proxy: proxy, elapsedTime: elapsedTime)
                }
            }
            .clipShape(Rectangle())
            .overlay(alignment: .leading) {
                textOverlay()
            }
        }
        .onAppear {
            initialDate = Date()
        }
    }
    
    // MARK: - View Layers
    
    private var backgroundGradient: some View {
        let colors: [Color] = colorScheme == .dark
            ? [Color(red: 25/255, green: 30/255, blue: 35/255), Color(red: 15/255, green: 20/255, blue: 25/255)]
            : [Color(red: 240/255, green: 245/255, blue: 250/255), Color(red: 220/255, green: 225/255, blue: 235/255)]
        
        return LinearGradient(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
    
    private func auroraView(proxy: GeometryProxy) -> some View {
        TimelineView(.animation(minimumInterval: 0.02, paused: false)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            ZStack {
                auroraShape(proxy: proxy, time: time, hue: 0.7, offsetX: -0.2, offsetY: -0.3, speed: 0.08, size: 0.6)
                auroraShape(proxy: proxy, time: time, hue: 0.5, offsetX: 0.3, offsetY: 0.3, speed: 0.06, size: 0.8)
                auroraShape(proxy: proxy, time: time, hue: 0.1, offsetX: 0.2, offsetY: -0.2, speed: 0.05, size: 0.5)
            }
            .blendMode(.plusLighter)
        }
    }
    
    private func auroraShape(proxy: GeometryProxy, time: TimeInterval, hue: Double, offsetX: Double, offsetY: Double, speed: Double, size: Double) -> some View {
        Circle()
            .fill(
                Color(hue: (sin(time * speed) + 1) / 2 * 0.2 + hue, saturation: 0.7, brightness: 0.8)
            )
            .frame(width: proxy.size.width * size, height: proxy.size.width * size)
            .offset(x: cos(time * speed * 1.2) * proxy.size.width * offsetX, y: sin(time * speed * 1.5) * proxy.size.height * offsetY)
            .blur(radius: 120)
    }
    
    private func floatingShapes(proxy: GeometryProxy) -> some View {
        ZStack {
            Circle().fill(Color.accentColor.opacity(0.3)).frame(width: proxy.size.width * 0.2, height: proxy.size.width * 0.2).offset(x: -proxy.size.width * 0.25, y: -proxy.size.height * 0.3).blur(radius: 80)
            Capsule().fill(Color.purple.opacity(0.3)).frame(width: proxy.size.width * 0.3, height: proxy.size.width * 0.15).offset(x: proxy.size.width * 0.28, y: proxy.size.height * 0.25).blur(radius: 90)
        }
    }

    private func cardStack(proxy: GeometryProxy, elapsedTime: TimeInterval) -> some View {
        let laneData: [(yOffset: CGFloat, speed: Double, reversed: Bool, cards: [AnyView])] = [
            (yOffset: -210, speed: 65, reversed: false, cards: [
                AnyView(InteractiveCard(zPosition: 0) { PlaceholderFlightCard(flight: DummySignInData.nzFlight) }),
                AnyView(InteractiveCard(zPosition: -0.8) { PlaceholderItineraryCard(item: DummySignInData.lobbyCall) }),
                AnyView(InteractiveCard(zPosition: -1.6) { PlaceholderVenueCard(venue: DummySignInData.venue) })
            ]),
            (yOffset: -70, speed: 80, reversed: false, cards: [
                AnyView(InteractiveCard(zPosition: -0.5) { PlaceholderItineraryCard(item: DummySignInData.interview) }),
                AnyView(InteractiveCard(zPosition: -1.4) { PlaceholderItineraryCard(item: DummySignInData.hiltonCheckin) }),
                AnyView(InteractiveCard(zPosition: -1.0) { PlaceholderFlightCard(flight: DummySignInData.uaFlight) }),
                AnyView(InteractiveCard(zPosition: -1.8) { PlaceholderContactCard(contact: DummySignInData.tourManager) })
            ]),
            (yOffset: 70, speed: 55, reversed: false, cards: [
                AnyView(InteractiveCard(zPosition: -0.6) { PlaceholderFlightCard(flight: DummySignInData.qfFlight) }),
                AnyView(InteractiveCard(zPosition: -1.0) { PlaceholderItineraryCard(item: DummySignInData.soundcheck) }),
                AnyView(InteractiveCard(zPosition: -0.4) { PlaceholderItineraryCard(item: DummySignInData.dinner) })
            ]),
            (yOffset: 210, speed: 70, reversed: false, cards: [
                AnyView(InteractiveCard(zPosition: -0.2) { PlaceholderFlightCard(flight: DummySignInData.aaFlight) }),
                AnyView(InteractiveCard(zPosition: -1.2) { PlaceholderFlightCard(flight: DummySignInData.ekFlight) }),
                AnyView(InteractiveCard(zPosition: -0.7) { PlaceholderItineraryCard(item: DummySignInData.dayOff) }),
                AnyView(InteractiveCard(zPosition: -1.2) { PlaceholderFlightCard(flight: DummySignInData.sqFlight) })
            ])
        ]
        
        return ZStack {
            ForEach(laneData.indices, id: \.self) { index in
                LaneView(
                    proxy: proxy,
                    cards: laneData[index].cards,
                    yOffset: laneData[index].yOffset,
                    speed: laneData[index].speed,
                    zPosition: CGFloat(index)
                )
            }
        }
    }

    private func textOverlay() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Text("YOUR ")
                    .font(.system(size: 24, weight: .bold))
                
                TypingEffectTextView(words: ["TOUR", "SHOW", "FLIGHTS", "ITINERARY", "HOTEL", "CREW", "GUEST LIST"])
                    .font(.system(size: 24, weight: .bold))
            }
            .foregroundColor(.secondary)
            
            Text("MANAGED")
                .font(.system(size: 48, weight: .bold))
                .kerning(-1)
                .foregroundColor(.primary)
                .padding(.bottom, 8)
            
            Text("Plan, manage, and track every detail—without the chaos.")
                .font(.title3)
                .foregroundColor(.secondary)
                .lineSpacing(6)
                .frame(maxWidth: 400, alignment: .leading)
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .allowsHitTesting(false)
    }
}

// MARK: - Animation and Helper Views

fileprivate struct LaneView: View {
    let proxy: GeometryProxy
    @State private var elapsedTime: Double = 0.0
    
    let cards: [AnyView]
    let yOffset: CGFloat
    let speed: Double
    let zPosition: CGFloat
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.016, paused: false)) { context in
            let cardSpacing: CGFloat = 450
            let cardWidth: CGFloat = 300
            let laneContentWidth = CGFloat(cards.count) * (cardWidth + cardSpacing)
            
            let duplicatedCards = HStack(spacing: cardSpacing) {
                ForEach(0..<cards.count, id: \.self) { i in cards[i] }
                ForEach(0..<cards.count, id: \.self) { i in cards[i] }
            }
            
            let loopingX = (elapsedTime * speed).truncatingRemainder(dividingBy: laneContentWidth)
            
            duplicatedCards
                .offset(x: -loopingX)
                .offset(y: yOffset)
                .zIndex(zPosition)
                .onAppear { elapsedTime = context.date.timeIntervalSinceReferenceDate }
                .onChange(of: context.date) { _,_ in // Updated for new onChange signature
                    elapsedTime += 0.016
                }
        }
    }
}


fileprivate struct InteractiveCard<Content: View>: View {
    let zPosition: CGFloat
    let content: Content
    
    @State private var isHovered = false
    
    init(zPosition: CGFloat, @ViewBuilder content: () -> Content) {
        self.zPosition = zPosition
        self.content = content()
    }
    
    var body: some View {
        let baseScale = 1.0 + (zPosition * 0.05)
        let hoverScale = isHovered ? 1.05 : 1.0
        let baseBlurRadius = max(0, -zPosition * 1.5)
        
        content
            .scaleEffect(baseScale * hoverScale)
            .blur(radius: isHovered ? 0 : baseBlurRadius)
            .zIndex(isHovered ? 100 : zPosition)
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.35)) {
                    isHovered = hovering
                }
            }
    }
}

fileprivate struct TypingEffectTextView: View {
    let words: [String]
    
    @State private var currentWordIndex = 0
    @State private var visibleCharacters = 0
    @State private var state: TypingState = .typing
    @State private var pauseCounter = 0
    
    private enum TypingState { case typing, paused, deleting }
    private let typingDelay = 0.12
    private let pauseTicks = 15
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(String(words[currentWordIndex].prefix(visibleCharacters)))
              .frame(width: 250, alignment: .leading)
            .onReceive(timer) { _ in
                animateText()
            }
    }
    
    private func animateText() {
        switch state {
        case .typing:
            if visibleCharacters < words[currentWordIndex].count {
                visibleCharacters += 1
            } else {
                state = .paused
            }
        case .paused:
            if pauseCounter < pauseTicks {
                pauseCounter += 1
            } else {
                pauseCounter = 0
                state = .deleting
            }
        case .deleting:
            if visibleCharacters > 0 {
                  visibleCharacters -= 1
            } else {
                state = .typing
                currentWordIndex = (currentWordIndex + 1) % words.count
            }
        }
    }
}


// MARK: - Dummy Data and Placeholder Views

fileprivate enum DummySignInData {
    private static func time(hour: Int, minute: Int) -> Date { Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date() }
    
    // --- THIS IS THE FIX ---
    // A dummy `ownerId` is now added to each placeholder Flight object.
    static let nzFlight = Flight(tourId: "d1", ownerId: "dummyOwner", airline: "Air New Zealand", flightNumber: "NZ102", departureTimeUTC: Timestamp(date: time(hour: 8, minute: 0)), arrivalTimeUTC: Timestamp(date: time(hour: 11, minute: 30)), origin: "AKL", destination: "SYD", passengers: [])
    static let aaFlight = Flight(tourId: "d2", ownerId: "dummyOwner", airline: "American Airlines", flightNumber: "AA118", departureTimeUTC: Timestamp(date: time(hour: 18, minute: 30)), arrivalTimeUTC: Timestamp(date: time(hour: 23, minute: 50)), origin: "LAX", destination: "JFK", passengers: [])
    static let qfFlight = Flight(tourId: "d3", ownerId: "dummyOwner", airline: "Qantas", flightNumber: "QF44", departureTimeUTC: Timestamp(date: time(hour: 10, minute: 0)), arrivalTimeUTC: Timestamp(date: time(hour: 14, minute: 0)), origin: "SYD", destination: "LAX", passengers: [])
    static let sqFlight = Flight(tourId: "d4", ownerId: "dummyOwner", airline: "Singapore Airlines", flightNumber: "SQ317", departureTimeUTC: Timestamp(date: time(hour: 23, minute: 0)), arrivalTimeUTC: Timestamp(date: time(hour: 5, minute: 0)), origin: "SIN", destination: "LHR", passengers: [])
    static let ekFlight = Flight(tourId: "d5", ownerId: "dummyOwner", airline: "Emirates", flightNumber: "EK413", departureTimeUTC: Timestamp(date: time(hour: 10, minute: 50)), arrivalTimeUTC: Timestamp(date: time(hour: 18, minute: 20)), origin: "DXB", destination: "AKL", passengers: [])
    static let uaFlight = Flight(tourId: "d6", ownerId: "dummyOwner", airline: "United Airlines", flightNumber: "UA90", departureTimeUTC: Timestamp(date: time(hour: 22, minute: 45)), arrivalTimeUTC: Timestamp(date: time(hour: 6, minute: 15)), origin: "SFO", destination: "SYD", passengers: [])
    // --- END OF FIX ---
    
    static let hiltonCheckin = DummyItineraryItem(type: .hotel, title: "Check into Hilton", time: time(hour: 15, minute: 0), subtitle: "Room 1204")
    static let soundcheck = DummyItineraryItem(type: .mic, title: "Soundcheck", time: time(hour: 16, minute: 0), subtitle: "Spark Arena")
    static let lobbyCall = DummyItineraryItem(type: .travel, title: "Lobby Call", time: time(hour: 11, minute: 0), subtitle: "To Airport")
    static let dinner = DummyItineraryItem(type: .food, title: "Dinner Reservation", time: time(hour: 20, minute: 0), subtitle: "The French Cafe")
    static let interview = DummyItineraryItem(type: .promo, title: "Radio Interview", time: time(hour: 13, minute: 0), subtitle: "ZM Radio")
    static let dayOff = DummyItineraryItem(type: .dayOff, title: "Day Off", time: time(hour: 0, minute: 0), subtitle: "Explore the city")
    static let tourManager = DummyContactItem(name: "Alex Johnson", role: "Tour Manager")
    static let venue = DummyVenueItem(name: "Tuning Fork", city: "Auckland")
}

fileprivate enum DummyItineraryType {
    case hotel, mic, travel, food, promo, dayOff
    var iconName: String {
        switch self {
        case .hotel: return "bed.double.fill"
        case .mic: return "music.mic"
        case .travel: return "car.fill"
        case .food: return "fork.knife"
        case .promo: return "megaphone.fill"
        case .dayOff: return "sun.max.fill"
        }
    }
}
fileprivate struct DummyItineraryItem { let type: DummyItineraryType; let title: String; let time: Date; let subtitle: String? }
fileprivate struct DummyContactItem { let name: String; let role: String }
fileprivate struct DummyVenueItem { let name: String; let city: String }

fileprivate struct PlaceholderFlightCard: View {
    let flight: Flight
    private var airlineCode: String { String(flight.flightNumber?.prefix(2) ?? "") }
    private var isDarkTheme: Bool { airlineCode == "NZ" }
    private var isCustomColorTheme: Bool { airlineCode == "SQ" }
    private var logoName: String { isDarkTheme ? "\(airlineCode)_icon_light" : "\(airlineCode)_icon" }
    private var cardBackgroundColor: Color {
        if isDarkTheme { return Color.black.opacity(0.85) }
        if isCustomColorTheme { return Color(red: 38/255, green: 78/255, blue: 138/255) }
        return Color.white.opacity(0.85)
    }
    var body: some View {
        HStack(spacing: 16) {
            Image(logoName).resizable().aspectRatio(contentMode: .fit).frame(width: 44, height: 44)
              VStack(alignment: .leading, spacing: 2) {
                Text("\(flight.origin) → \(flight.destination)").font(.system(size: 20, weight: .bold))
                Text("\(flight.airline ?? "") \(flight.flightNumber ?? "")").font(.caption).opacity(0.8)
            }
            Spacer()
        }
        .padding().foregroundColor(isDarkTheme || isCustomColorTheme ? .white : .black).background(cardBackgroundColor.background(.ultraThinMaterial)).cornerRadius(16).frame(width: 300).shadow(color: .black.opacity(isDarkTheme || isCustomColorTheme ? 0.3 : 0.1), radius: 10)
    }
}
fileprivate struct PlaceholderItineraryCard: View {
    let item: DummyItineraryItem
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: item.type.iconName).font(.title2.weight(.medium)).foregroundColor(.accentColor).frame(width: 30)
            VStack(alignment: .leading) {
                Text(item.title).fontWeight(.bold)
                if let subtitle = item.subtitle { Text(subtitle).font(.subheadline).foregroundColor(.secondary) }
            }
            Spacer()
            Text(item.time, style: .time).font(.subheadline).foregroundColor(.secondary)
        }
        .padding().background(.regularMaterial).cornerRadius(16).frame(width: 300).shadow(color: .black.opacity(0.2), radius: 8)
    }
}
fileprivate struct PlaceholderContactCard: View {
    let contact: DummyContactItem
    var body: some View {
        HStack(spacing: 16) {
              Image(systemName: "person.text.rectangle.fill").font(.title2.weight(.medium)).foregroundColor(.accentColor).frame(width: 30)
            VStack(alignment: .leading) {
                Text(contact.name).fontWeight(.bold)
                Text(contact.role).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding().background(.regularMaterial).cornerRadius(16).frame(width: 300).shadow(color: .black.opacity(0.2), radius: 8)
    }
}
fileprivate struct PlaceholderVenueCard: View {
    let venue: DummyVenueItem
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "mappin.and.ellipse").font(.title2.weight(.medium)).foregroundColor(.accentColor).frame(width: 30)
            VStack(alignment: .leading) {
                Text(venue.name).fontWeight(.bold)
                Text(venue.city).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding().background(.regularMaterial).cornerRadius(16).frame(width: 300).shadow(color: .black.opacity(0.2), radius: 8)
    }
}
