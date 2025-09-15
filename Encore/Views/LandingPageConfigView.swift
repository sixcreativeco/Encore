import SwiftUI
import Kingfisher
import UniformTypeIdentifiers
import FirebaseFirestore
import FirebaseStorage
import Combine

// MARK: - Foundational Helper Views

fileprivate struct PreviewModeSwitch: View {
    @Binding var selection: LandingPageConfigView.PreviewDevice

    private let chromeBG = Color.black.opacity(0.15)
    private let selBG = Color.accentColor.opacity(0.22)
    private let selStroke = Color.accentColor
    private let unselStroke = Color.white.opacity(0.15)
    private let selFG = Color.white
    private let unselFG = Color(white: 0.85)

    var body: some View {
        HStack(spacing: 6) {
            modeButton(.desktop, systemName: "desktopcomputer")
            modeButton(.mobile, systemName: "iphone")
        }
        .padding(4)
        .background(chromeBG)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func modeButton(_ mode: LandingPageConfigView.PreviewDevice, systemName: String) -> some View {
        let isSelected = selection == mode
        Button {
            withAnimation(.snappy) { selection = mode }
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 28, height: 24)
                .foregroundColor(isSelected ? selFG : unselFG)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isSelected ? selBG : .clear)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? selStroke : unselStroke, lineWidth: isSelected ? 1.5 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityLabel(mode == .desktop ? "Desktop preview" : "Mobile preview")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

fileprivate struct ThemePreviewCard: View {
    let theme: LandingPageTheme
    let isSelected: Bool
    private var themeColor: Color { .accentColor }

    var body: some View {
        VStack(spacing: 8) {
            Group {
                switch theme {
                case .default:
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 58/255, green: 96/255, blue: 115/255),
                                Color(red: 22/255, green: 34/255, blue: 42/255)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        VStack(spacing: 6) {
                            Capsule().frame(width: 40, height: 5).foregroundColor(.white.opacity(0.8))
                            Capsule().frame(width: 60, height: 7).foregroundColor(.white)
                        }
                    }
                case .darkMode:
                    ZStack {
                        Color(white: 0.15)
                        VStack {
                            Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 50)
                            Spacer()
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 4).fill(.gray.opacity(0.2)).frame(height: 12)
                                RoundedRectangle(cornerRadius: 4).fill(.gray.opacity(0.2)).frame(height: 12)
                            }
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                        }
                        Capsule().frame(width: 60, height: 7).foregroundColor(.white).offset(y: -20)
                    }
                case .print:
                    ZStack {
                        Color.white
                        VStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2)).frame(height: 40)
                            Capsule().frame(width: 70, height: 6).foregroundColor(.black.opacity(0.8))
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.5)).frame(height: 12)
                                RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.5)).frame(height: 12)
                            }
                        }
                        .padding(10)
                    }
                case .scrapbook:
                    ZStack {
                        Color.white
                        ZStack {
                            Rectangle().fill(Color.gray.opacity(0.2)).frame(width: 60, height: 60).offset(x: -10, y: -10)
                            Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 30, height: 50).offset(x: 10, y: 5)
                        }
                        .offset(y: -15)
                        VStack {
                            Spacer()
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 4).fill(themeColor).frame(height: 12)
                                RoundedRectangle(cornerRadius: 4).fill(themeColor).frame(height: 12)
                            }
                        }
                        .padding(10)
                    }
                }
            }
            .frame(height: 120)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? themeColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
            )
            .padding(2)

            Text(theme.rawValue)
                .font(.caption)
                .foregroundColor(isSelected ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Granular Control Views

fileprivate struct URLConfigurationView: View {
    @Binding var urlSlug: String
    @Binding var availabilityStatus: LandingPageViewModel.URLAvailabilityStatus
    @Binding var tour: Tour
    let checkUrlAvailability: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom URL").font(.headline)
            HStack(spacing: 0) {
                Text("en-co.re/t/")
                    .font(.headline)
                    .padding(12)
                    .background(Color.black.opacity(0.15))
                TextField("your-tour-name", text: $urlSlug)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(Color.black.opacity(0.25))
                    .onChange(of: urlSlug) { _ in checkUrlAvailability() }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                switch availabilityStatus {
                case .idle:
                    EmptyView()
                case .checking:
                    ProgressView().scaleEffect(0.5)
                case .available:
                    Label("Available!", systemImage: "checkmark.circle.fill").foregroundColor(.green)
                case .unavailable(let msg):
                    Label(msg, systemImage: "xmark.circle.fill").foregroundColor(.red)
                case .error(let msg):
                    Label(msg, systemImage: "exclamationmark.triangle.fill").foregroundColor(.orange)
                }
                Spacer()
                if tour.isLandingPagePublished == true,
                   let urlString = tour.landingPageUrl,
                   let url = URL(string: "https://en-co.re/t/\(urlString)") {
                    Link(destination: url) {
                        Label("Go to Link", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.plain)
                }
            }
            .font(.caption)
            .frame(height: 20)
        }
    }
}

fileprivate struct BioConfigurationView: View {
    @Binding var tour: Tour
    @State private var bioText: String

    init(tour: Binding<Tour>) {
        _tour = tour
        _bioText = State(initialValue: tour.wrappedValue.landingPageBio ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tour Bio").font(.headline)
                Spacer()
                Text("\(bioText.count) / 200")
                    .font(.caption)
                    .foregroundColor(bioText.count > 200 ? .red : .secondary)
            }

            CustomTextEditor(
                placeholder: "Add a short description for your tour...",
                text: Binding(
                    get: { bioText },
                    set: { newValue in
                        let clipped = String(newValue.prefix(200))
                        bioText = clipped
                        tour.landingPageBio = clipped.isEmpty ? nil : clipped
                    }
                )
            )
            .frame(height: 120)
        }
    }
}

fileprivate struct ThemeSelectorView: View {
    @Binding var selection: LandingPageTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Theme").font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(LandingPageTheme.allCases, id: \.self) { theme in
                    ThemePreviewCard(theme: theme, isSelected: selection == theme)
                        .onTapGesture { withAnimation(.easeInOut) { selection = theme } }
                }
            }
        }
    }
}

fileprivate struct FooterButtonsView: View {
    @Binding var tour: Tour
    @Binding var isSaving: Bool
    @Binding var availabilityStatus: LandingPageViewModel.URLAvailabilityStatus

    let unpublishPage: () -> Void
    let saveChanges: (Bool) -> Void
    let publishPage: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if tour.isLandingPagePublished == true {
                Button(action: unpublishPage) {
                    Text("Unpublish").fontWeight(.semibold).frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(color: .red.opacity(0.8), isLoading: isSaving))

                Button(action: { saveChanges(true) }) {
                    Text("Save Changes & Refresh Site").fontWeight(.semibold).frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(color: .blue, isLoading: isSaving))
            } else {
                Button(action: { saveChanges(false) }) {
                    Text("Save").fontWeight(.semibold).frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                Button(action: publishPage) {
                    Text("Publish").fontWeight(.semibold).frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(color: .green, isLoading: isSaving))
                .disabled(availabilityStatus != .available || isSaving)
            }
        }
    }
}

// MARK: - Column Views

fileprivate struct ControlsColumnView: View {
    @Binding var tour: Tour
    @Binding var urlSlug: String
    @Binding var availabilityStatus: LandingPageViewModel.URLAvailabilityStatus
    @Binding var isSaving: Bool
    @Binding var themeSelection: LandingPageTheme

    let checkUrlAvailability: () -> Void
    let saveChanges: (Bool) -> Void
    let publishPage: () -> Void
    let unpublishPage: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                URLConfigurationView(
                    urlSlug: $urlSlug,
                    availabilityStatus: $availabilityStatus,
                    tour: $tour,
                    checkUrlAvailability: checkUrlAvailability
                )
                BioConfigurationView(tour: $tour)
                ThemeSelectorView(selection: $themeSelection)
                Spacer()
                FooterButtonsView(
                    tour: $tour,
                    isSaving: $isSaving,
                    availabilityStatus: $availabilityStatus,
                    unpublishPage: unpublishPage,
                    saveChanges: saveChanges,
                    publishPage: publishPage
                )
            }
            .padding(30)
        }
    }
}

fileprivate struct PreviewColumnView: View {
    @Binding var tour: Tour
    @Binding var previewMode: LandingPageConfigView.PreviewDevice
    let onUpload: (Int) -> Void

    var body: some View {
        VStack(spacing: 20) {
            PreviewModeSwitch(selection: $previewMode)
                .padding(.top, 10)
                .zIndex(1)

            ZStack {
                switch tour.landingPageTheme ?? .default {
                case .default:
                    DefaultPreviewView(tour: $tour, onUpload: onUpload, previewMode: previewMode)
                case .darkMode:
                    DarkModePreviewView(tour: $tour, onUpload: onUpload, previewMode: previewMode)
                case .print:
                    PrintPreviewView(tour: $tour, onUpload: onUpload, previewMode: previewMode)
                case .scrapbook:
                    ScrapbookPreviewView(tour: $tour, onUpload: onUpload, previewMode: previewMode)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.2))
            .cornerRadius(16)
            .shadow(radius: 10)
        }
        .padding([.horizontal, .bottom], 20)
    }
}

// MARK: - Main View

struct LandingPageConfigView: View {
    @Binding var tour: Tour

    @Environment(\.dismiss) var dismiss

    @State private var urlSlug: String
    @State private var availabilityStatus: LandingPageViewModel.URLAvailabilityStatus = .idle
    @State private var isSaving = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var cancellable: AnyCancellable? = nil

    @State private var showingFileImporter = false
    @State private var importerSlot: Int = 1
    @State private var previewMode: PreviewDevice = .desktop
    @State private var themeSelection: LandingPageTheme

    enum PreviewDevice: String, CaseIterable {
        case desktop = "Desktop"
        case mobile = "Mobile"
    }

    init(tour: Binding<Tour>) {
        self._tour = tour
        self._urlSlug = State(initialValue: tour.wrappedValue.landingPageUrl ?? "")
        self._themeSelection = State(initialValue: tour.wrappedValue.landingPageTheme ?? .default)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            HStack(spacing: 0) {
                ControlsColumnView(
                    tour: $tour,
                    urlSlug: $urlSlug,
                    availabilityStatus: $availabilityStatus,
                    isSaving: $isSaving,
                    themeSelection: $themeSelection,
                    checkUrlAvailability: self.checkUrlAvailability,
                    saveChanges: self.saveChanges,
                    publishPage: self.publishPage,
                    unpublishPage: self.unpublishPage
                )
                .frame(width: 380)
                .background(Material.regular)

                PreviewColumnView(
                    tour: $tour,
                    previewMode: $previewMode,
                    onUpload: self.handleUpload
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 1200, minHeight: 800)
        .onAppear {
            if !urlSlug.isEmpty { availabilityStatus = .available }
        }
        .onChange(of: themeSelection) { newValue in
            tour.landingPageTheme = newValue
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [UTType.image, UTType.video, UTType.movie]
        ) { result in
            if case .success(let url) = result {
                uploadMedia(fileURL: url, for: importerSlot)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("Landing Page")
                .font(.largeTitle.bold())

            if tour.isLandingPagePublished == true {
                Text("• Live")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(6)
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
        .padding(30)
    }

    private func handleUpload(slot: Int) {
        self.importerSlot = slot
        self.showingFileImporter = true
    }
}

// MARK: - Logic Extension

extension LandingPageConfigView {
    func uploadMedia(fileURL: URL, for slot: Int = 1) {
        guard fileURL.startAccessingSecurityScopedResource() else {
            print("❌ Failed to gain access to the file URL.")
            return
        }

        guard let tourId = tour.id else {
            fileURL.stopAccessingSecurityScopedResource()
            return
        }
        isUploading = true
        uploadProgress = 0.0

        let storageRef = Storage.storage().reference().child("landing_headers/\(tourId)/\(UUID().uuidString)")
        let uploadTask = storageRef.putFile(from: fileURL, metadata: nil)

        uploadTask.observe(.progress) { snapshot in
            if let progress = snapshot.progress {
                self.uploadProgress = progress.fractionCompleted
            }
        }

        uploadTask.observe(.success) { _ in
            storageRef.downloadURL { url, error in
                defer { fileURL.stopAccessingSecurityScopedResource() }

                guard let downloadURL = url else {
                    print("❌ Error getting download URL: \(error?.localizedDescription ?? "Unknown error")")
                    self.isUploading = false
                    return
                }

                let urlString = downloadURL.absoluteString
                let isVideo = ["mov", "mp4", "m4v"].contains(fileURL.pathExtension.lowercased())

                if slot == 1 {
                    self.tour.landingPageHeaderImageUrl = isVideo ? nil : urlString
                    self.tour.landingPageHeaderVideoUrl = isVideo ? urlString : nil
                } else if slot == 2 {
                    self.tour.landingPageScrapbookImageUrl2 = urlString
                }
                self.isUploading = false
            }
        }

        uploadTask.observe(.failure) { snapshot in
            defer { fileURL.stopAccessingSecurityScopedResource() }

            if let error = snapshot.error {
                print("❌ Error during document upload: \(error.localizedDescription)")
            }
            self.isUploading = false
        }
    }

    func saveChanges(andRefresh refresh: Bool) {
        guard let tourId = tour.id else { return }
        isSaving = true
        tour.landingPageUrl = self.urlSlug
        tour.landingPageTheme = self.themeSelection

        do {
            try Firestore.firestore().collection("tours").document(tourId).setData(from: self.tour, merge: true) { error in
                if let error = error {
                    print("❌ Error saving landing page: \(error.localizedDescription)")
                    self.isSaving = false
                    return
                }

                print("✅ Landing page saved.")
                if refresh { self.refreshPage() }
                self.isSaving = false
            }
        } catch {
            print("❌ Error encoding tour for save: \(error.localizedDescription)")
            self.isSaving = false
        }
    }

    func publishPage() {
        tour.isLandingPagePublished = true
        saveChanges(andRefresh: true)
    }

    func unpublishPage() {
        tour.isLandingPagePublished = false
        saveChanges(andRefresh: true)
    }

    func refreshPage() {
        guard let tourId = tour.id else { return }
        TicketingAPI.shared.refreshEventPage(eventId: tourId) { _ in }
    }

    func checkUrlAvailability() {
        let cleanSlug = urlSlug
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()

        guard !cleanSlug.isEmpty else {
            availabilityStatus = .idle
            return
        }

        if cleanSlug == tour.landingPageUrl {
            availabilityStatus = .available
            return
        }

        availabilityStatus = .checking
        cancellable?.cancel()

        cancellable = Just(cleanSlug)
            .delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .flatMap { slug -> AnyPublisher<Bool, Error> in
                Future<Bool, Error> { promise in
                    Firestore.firestore()
                        .collection("tours")
                        .whereField("landingPageUrl", isEqualTo: slug)
                        .getDocuments { snapshot, error in
                            if let error = error {
                                promise(.failure(error))
                            } else {
                                promise(.success(snapshot?.isEmpty ?? true))
                            }
                        }
                }
                .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.availabilityStatus = .error(error.localizedDescription)
                    }
                },
                receiveValue: { isAvailable in
                    self.availabilityStatus = isAvailable ? .available : .unavailable("URL is already taken.")
                }
            )
    }
}
