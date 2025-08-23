import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

@MainActor
class ExportViewModel: ObservableObject {
    @Published var tours: [Tour] = []
    @Published var selectedTourID: String? {
        didSet {
            if let tourID = selectedTourID {
                fetchDataForTour(tourID: tourID)
            } else {
                selectedTourData = nil
                showsForSelectedTour = []
                crewForSelectedTour = []
                previewImages = []
            }
        }
    }
    @Published var isLoading = false
    @Published var isGeneratingPDF = false

    // Data for the selected tour
    @Published var selectedTourData: Tour?
    @Published var showsForSelectedTour: [Show] = []
    @Published var crewForSelectedTour: [TourCrew] = []
    @Published var itineraryForSelectedTour: [ItineraryItem] = []
    @Published var flightsForSelectedTour: [Flight] = []
    @Published var hotelsForSelectedTour: [Hotel] = []
    @Published var guestLists: [String: [GuestListItemModel]] = [:]

    // Configuration & Preview
    @Published var config = ExportConfiguration()
    @Published var previewImages: [NSImage] = [] // Changed to an array for multiple pages
    @Published var currentPreviewPage: Int = 0

    private let db = Firestore.firestore()
    private let userID: String?
    private var configCancellable: AnyCancellable?

    init(userID: String?) {
        self.userID = userID
        guard let userID = userID else { return }
        fetchTours(for: userID)
        
        configCancellable = $config
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.generatePreview() }
            }
    }

    private func fetchTours(for userID: String) {
        isLoading = true
        db.collection("tours").whereField("ownerId", isEqualTo: userID)
            .order(by: "startDate", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    self?.isLoading = false
                    return
                }
                self.tours = documents.compactMap { try? $0.data(as: Tour.self) }
                self.isLoading = false
            }
    }

    private func fetchDataForTour(tourID: String) {
        self.selectedTourData = tours.first { $0.id == tourID }
        self.config = ExportConfiguration()
        
        Task {
            isLoading = true
            do {
                let shows = try await FirebaseTourService.fetchShows(forTour: tourID)
                self.showsForSelectedTour = shows
                self.config.selectedShowID = shows.first?.id
                
                async let crewTask: Void = fetchCrew(for: tourID)
                async let itineraryTask: Void = fetchItinerary(for: tourID)
                async let flightsTask: Void = fetchFlights(for: tourID)
                async let hotelsTask: Void = fetchHotels(for: tourID)
                async let guestListTask: Void = fetchAllGuestLists(for: shows)

                _ = await [crewTask, itineraryTask, flightsTask, hotelsTask, guestListTask]
                
                await generatePreview()

            } catch {
                print("Error fetching tour details: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
    
    private func fetchCrew(for tourID: String) async {
        self.crewForSelectedTour = (try? await FirebaseTourService.loadCrew(forTour: tourID)) ?? []
    }
    
    private func fetchItinerary(for tourID: String) async {
        let snapshot = try? await db.collection("itineraryItems").whereField("tourId", isEqualTo: tourID).getDocuments()
        self.itineraryForSelectedTour = snapshot?.documents.compactMap { try? $0.data(as: ItineraryItem.self) } ?? []
    }

    private func fetchFlights(for tourID: String) async {
        let snapshot = try? await db.collection("flights").whereField("tourId", isEqualTo: tourID).getDocuments()
        self.flightsForSelectedTour = snapshot?.documents.compactMap { try? $0.data(as: Flight.self) } ?? []
    }

    private func fetchHotels(for tourID: String) async {
        let snapshot = try? await db.collection("hotels").whereField("tourId", isEqualTo: tourID).getDocuments()
        self.hotelsForSelectedTour = snapshot?.documents.compactMap { try? $0.data(as: Hotel.self) } ?? []
    }
    
    private func fetchAllGuestLists(for shows: [Show]) async {
        var allGuests: [String: [GuestListItemModel]] = [:]
        for show in shows {
            guard let showID = show.id else { continue }
            let snapshot = try? await db.collection("shows").document(showID).collection("guestlist").getDocuments()
            allGuests[showID] = snapshot?.documents.compactMap { GuestListItemModel(from: $0) } ?? []
        }
        self.guestLists = allGuests
    }
    
    private func generateConfiguredPDFView() async -> (view: AnyView?, suggestedName: String) {
        guard let tour = selectedTourData else { return (nil, "") }
        
        var viewToRender: AnyView?
        var suggestedName = "\(tour.artist) - \(tour.tourName) Export.pdf"
        
        var poster: NSImage? = nil
        if let posterURLString = tour.posterURL, let url = URL(string: posterURLString) {
            do {
                let resource = try await KingfisherManager.shared.downloader.downloadImage(with: url)
                poster = resource.image
            } catch {
                print("❌ Could not download poster for PDF: \(error)")
            }
        }
        
        switch config.selectedPreset {
        case .show:
            guard let show = showsForSelectedTour.first(where: { $0.id == config.selectedShowID }) else { return (nil, "") }
            viewToRender = AnyView(ShowDaySheetPDF(tour: tour, show: show, crew: crewForSelectedTour, config: config, posterImage: poster))
            suggestedName = "\(tour.artist) - \(show.city) Day Sheet.pdf"
        
        case .guestList:
            guard let show = showsForSelectedTour.first(where: { $0.id == config.selectedShowID }), let guests = guestLists[show.id ?? ""] else { return (nil, "") }
            viewToRender = AnyView(GuestListPDF(tour: tour, show: show, guests: guests))
            suggestedName = "\(tour.artist) - \(show.city) Guest List.pdf"
            
        case .travel:
            let travelItinerary = itineraryForSelectedTour.filter { ItineraryItemType(rawValue: $0.type) == .travel || ItineraryItemType(rawValue: $0.type) == .flight || ItineraryItemType(rawValue: $0.type) == .hotel }
            viewToRender = AnyView(TravelPDF(tour: tour, itinerary: travelItinerary, flights: flightsForSelectedTour, hotels: hotelsForSelectedTour, crew: crewForSelectedTour, posterImage: poster))
            suggestedName = "\(tour.artist) - Travel Itinerary.pdf"
            
        case .fullTour:
            viewToRender = AnyView(FullTourPDF(tour: tour, shows: showsForSelectedTour, itinerary: itineraryForSelectedTour, flights: flightsForSelectedTour, hotels: hotelsForSelectedTour, crew: crewForSelectedTour, posterImage: poster))
            suggestedName = "\(tour.artist) - \(tour.tourName) Full Itinerary.pdf"

        default:
            viewToRender = AnyView(Text("Export for \(config.selectedPreset.rawValue) not yet available.").frame(width: 595, height: 842).background(Color.white))
        }
        
        return (viewToRender, suggestedName)
    }
    
    func generatePreview() async {
        let result = await generateConfiguredPDFView()
        guard let view = result.view else {
            self.previewImages = []
            return
        }

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0

        guard let fullImage = renderer.nsImage else {
            self.previewImages = []
            return
        }

        let pageHeight: CGFloat = 842.0
        let fullHeight = fullImage.size.height
        let pageCount = Int(ceil(fullHeight / pageHeight))
        var images: [NSImage] = []

        if pageCount > 0 {
            for i in 0..<pageCount {
                let yOffset = CGFloat(i) * pageHeight
                let cropOriginY = fullHeight - yOffset - pageHeight
                let rectToDraw = NSRect(x: 0, y: cropOriginY, width: fullImage.size.width, height: pageHeight)
                
                if let croppedCGImage = fullImage.cgImage(forProposedRect: nil, context: nil, hints: nil)?.cropping(to: rectToDraw) {
                    let pageImage = NSImage(cgImage: croppedCGImage, size: NSSize(width: 595, height: 842))
                    images.append(pageImage)
                }
            }
        }

        self.previewImages = images
        self.currentPreviewPage = 0
    }
    
    func initiateSavePDF() async {
        isGeneratingPDF = true
        let result = await generateConfiguredPDFView()
        if let view = result.view {
            await PDFGenerator.generateAndSave(view: view, suggestedName: result.suggestedName)
        }
        isGeneratingPDF = false
    }
}
