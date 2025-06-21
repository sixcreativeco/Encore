import Foundation
import Combine
import FirebaseFirestore

class LiveSetlistViewModel: ObservableObject {
    // Tour and Show Info
    @Published var tour: Tour
    @Published var show: Show
    
    // Setlist Items - This is the single source of truth for the order.
    @Published var setlistItems: [SetlistItem] = []
    
    // Timer State
    @Published var elapsedTime: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var currentSongTitle: String = "Not Started"
    
    // View State
    @Published var selectedTab: SetlistTab = .main
    @Published var editingItemID: String? = nil
    @Published var selection = Set<String>()
    
    private var timer: AnyCancellable?
    private var listener: ListenerRegistration?
    
    enum DraggableItem: String {
        case song, note, lightingNote, soundNote, pageBreak
    }
    
    enum SetlistTab: String {
        case main = "Main"
        case artist = "Artist"
        case lighting = "Lighting"
        case sound = "Sound"
    }

    init(tour: Tour, show: Show) {
        self.tour = tour
        self.show = show
        listenForSetlistItems()
    }
    
    deinit {
        listener?.remove()
        timer?.cancel()
    }

    // MARK: - Timer Controls
    func toggleTimer() {
        if isRunning { pauseTimer() } else { startTimer() }
    }

    func startTimer() {
        isRunning = true
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            self?.elapsedTime += 1
            self?.updateCurrentSong()
        }
    }

    func pauseTimer() {
        isRunning = false
        timer?.cancel()
    }

    func stopTimer() {
        pauseTimer()
        elapsedTime = 0
        currentSongTitle = "Not Started"
    }
    
    private func updateCurrentSong() {
        let currentItems = setlistItems.filter { ($0.order * 240) < Int(elapsedTime) }
        if let lastSong = currentItems.last(where: { $0.type == .song }) {
            self.currentSongTitle = lastSong.songTitle ?? "Marker"
        }
    }

    // MARK: - Data Management
    func listenForSetlistItems() {
        guard let showID = show.id else { return }
        listener?.remove()
        
        listener = SetlistService.shared.addListener(forShow: showID) { [weak self] items in
            self?.setlistItems = items.sorted(by: { $0.order < $1.order })
        }
    }
    
    func updateItem(_ item: SetlistItem) {
        if let index = setlistItems.firstIndex(where: { $0.id == item.id }) {
            setlistItems[index] = item
        }
        SetlistService.shared.saveItem(item)
    }

    func createAndAddItem(ofType draggableType: DraggableItem, at index: Int) {
        let id = UUID().uuidString
        var newItem: SetlistItem

        switch draggableType {
        case .song:
            newItem = SetlistItem(id: id, showId: show.id ?? "", tourId: tour.id ?? "", order: 0, type: .song, songTitle: "")
        case .note:
            newItem = SetlistItem(id: id, showId: show.id ?? "", tourId: tour.id ?? "", order: 0, type: .marker, markerDescription: "Talking")
        case .lightingNote:
            newItem = SetlistItem(id: id, showId: show.id ?? "", tourId: tour.id ?? "", order: 0, type: .lightingNote, markerDescription: "Lighting Cue")
        case .soundNote:
            newItem = SetlistItem(id: id, showId: show.id ?? "", tourId: tour.id ?? "", order: 0, type: .soundNote, markerDescription: "Sound Cue")
        case .pageBreak:
            newItem = SetlistItem(id: id, showId: show.id ?? "", tourId: tour.id ?? "", order: 0, type: .a_break, markerDescription: "Section")
        }
        
        setlistItems.insert(newItem, at: index)
        reorderAndSaveAllItems()
        
        editingItemID = id
    }
    
    private func reorderAndSaveAllItems() {
        let batch = Firestore.firestore().batch()
        for (index, item) in setlistItems.enumerated() {
            var mutableItem = item
            mutableItem.order = index
            setlistItems[index] = mutableItem
            
            let docRef = Firestore.firestore().collection("setlists").document(mutableItem.id!)
            // FIX: This now uses setData with merge, which will create the document if it's new,
            // or update it if it exists. This prevents the "Not Found" error.
            do {
                try batch.setData(from: mutableItem, forDocument: docRef, merge: true)
            } catch {
                print("Error setting data for item \(mutableItem.id ?? "unknown") in batch: \(error)")
            }
        }
        batch.commit { error in
            if let error = error {
                print("Error committing setlist reorder batch: \(error)")
            }
        }
    }
    
    func deleteSelectedItems() {
        let selectedIDs = selection
        guard !selectedIDs.isEmpty else { return }
        
        selectedIDs.forEach { id in
            SetlistService.shared.deleteItem(id)
        }
        setlistItems.removeAll { selectedIDs.contains($0.id ?? "") }
        selection.removeAll()
        reorderAndSaveAllItems()
    }
}
