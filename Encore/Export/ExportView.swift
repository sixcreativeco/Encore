import SwiftUI
import FirebaseAuth
import Kingfisher

struct ExportView: View {
    @StateObject private var viewModel: ExportViewModel
    @EnvironmentObject var appState: AppState

    init() {
        _viewModel = StateObject(wrappedValue: ExportViewModel(userID: Auth.auth().currentUser?.uid))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header()
            
            if viewModel.isLoading {
                ProgressView("Loading Tours...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.tours.isEmpty {
                Text("No tours available to export. Create a tour to get started.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                exportConfigurationView()
            }
            
            Spacer()
        }
        .padding(30)
    }

    private func header() -> some View {
        Text("Export")
            .font(.largeTitle.bold())
    }

    private func exportConfigurationView() -> some View {
        HStack(alignment: .top, spacing: 30) {
            // Left Column: Configuration
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    tourSelector()
                    presetsSection()
                    
                    if viewModel.selectedTourID != nil {
                        switch viewModel.config.selectedPreset {
                        case .show:
                            showConfiguration()
                        case .guestList:
                            guestListConfiguration()
                        case .travel:
                            travelConfiguration()
                        case .date:
                            dateConfiguration()
                        case .fullTour:
                            fullTourConfiguration()
                        }
                    } else {
                        Text("Select a tour to begin.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    }
                }
            }
            .frame(width: 350)
            
            // Right Column: Preview
            rightPreviewPanel()
        }
    }
    
    private func rightPreviewPanel() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview").font(.headline).foregroundColor(.secondary)
            
            if viewModel.isLoading && viewModel.selectedTourID != nil {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !viewModel.previewImages.isEmpty {
                VStack {
                    Image(nsImage: viewModel.previewImages[viewModel.currentPreviewPage])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                    
                    if viewModel.previewImages.count > 1 {
                        paginationControls()
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.1))
                    .overlay(Text("Select a tour and preset to see a preview.").foregroundColor(.secondary))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func paginationControls() -> some View {
        HStack {
            Button(action: {
                if viewModel.currentPreviewPage > 0 { viewModel.currentPreviewPage -= 1 }
            }) { Image(systemName: "chevron.left") }
            .disabled(viewModel.currentPreviewPage == 0)
            
            Text("Page \(viewModel.currentPreviewPage + 1) of \(viewModel.previewImages.count)")
                .font(.caption)
            
            Button(action: {
                if viewModel.currentPreviewPage < viewModel.previewImages.count - 1 { viewModel.currentPreviewPage += 1 }
            }) { Image(systemName: "chevron.right") }
            .disabled(viewModel.currentPreviewPage == viewModel.previewImages.count - 1)
        }
        .buttonStyle(.plain)
    }
    
    private func tourSelector() -> some View {
        configSection(title: "Tour") {
            Menu {
                ForEach(viewModel.tours) { tour in
                    Button(tour.tourName) { viewModel.selectedTourID = tour.id }
                }
            } label: {
                HStack {
                    Text(viewModel.selectedTourData?.tourName ?? "Select a Tour...")
                        .foregroundColor(viewModel.selectedTourData == nil ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                }
                .padding(12)
                .background(Color.black.opacity(0.2))
                .cornerRadius(10)
            }
            .menuStyle(.borderlessButton)
            .frame(maxWidth: .infinity)
        }
    }

    private func presetsSection() -> some View {
        configSection(title: "Presets") {
            HStack(spacing: 10) {
                presetButton(preset: .show)
                presetButton(preset: .guestList)
                presetButton(preset: .travel)
            }
            HStack(spacing: 10) {
                presetButton(preset: .date)
                presetButton(preset: .fullTour)
            }
        }
    }
    
    private func showConfiguration() -> some View {
        configSection(title: "Show Preferences") {
            showPickerMenu()
            Toggle("Include Notes Section", isOn: $viewModel.config.includeNotesSection).toggleStyle(.checkbox)
            if viewModel.config.includeNotesSection {
                CustomTextEditor(placeholder: "Add custom notes for the PDF...", text: $viewModel.config.notes)
                    .frame(height: 100)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(10)
            }
            Toggle("Include Crew List", isOn: $viewModel.config.includeCrew).toggleStyle(.checkbox)
            exportButton()
        }
    }
    
    private func guestListConfiguration() -> some View {
        configSection(title: "Guest List Preferences") {
            showPickerMenu()
            exportButton()
        }
    }
    
    private func travelConfiguration() -> some View {
        configSection(title: "Travel Preferences") {
            exportButton()
        }
    }
    
    private func fullTourConfiguration() -> some View {
        configSection(title: "Full Tour Preferences") {
            Toggle("Include Cover Page", isOn: $viewModel.config.includeCoverPage).toggleStyle(.checkbox)
            if viewModel.config.includeCoverPage {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Theme").font(.caption).foregroundColor(.secondary)
                    HStack(spacing: 12) {
                        ThemePreviewCard(theme: .theme1, isSelected: viewModel.config.coverPageTheme == .theme1)
                            .onTapGesture { viewModel.config.coverPageTheme = .theme1 }
                        ThemePreviewCard(theme: .theme2, isSelected: viewModel.config.coverPageTheme == .theme2)
                            .onTapGesture { viewModel.config.coverPageTheme = .theme2 }
                    }
                }
            }
            exportButton()
        }
    }
    
    private func dateConfiguration() -> some View {
        configSection(title: "Date Preferences") {
            Text("Date range pickers coming soon.")
                .font(.caption)
                .foregroundColor(.secondary)
            exportButton().disabled(true)
        }
    }

    private func showPickerMenu() -> some View {
        Menu {
            ForEach(viewModel.showsForSelectedTour) { show in
                Button("\(show.city) - \(show.venueName)") {
                    viewModel.config.selectedShowID = show.id
                }
            }
        } label: {
            HStack {
                if let show = viewModel.showsForSelectedTour.first(where: { $0.id == viewModel.config.selectedShowID }) {
                    Text("\(show.city) - \(show.venueName)")
                } else {
                    Text("Select a show...").foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.down")
            }
            .padding(12)
            .background(Color.black.opacity(0.2))
            .cornerRadius(10)
        }
        .menuStyle(.borderlessButton)
        .frame(maxWidth: .infinity)
    }

    private func exportButton() -> some View {
        Button(action: {
            Task { await viewModel.initiateSavePDF() }
        }) {
            Text("Export")
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.selectedTourID == nil || viewModel.isGeneratingPDF)
        .padding(.top)
    }

    private func configSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).foregroundColor(.secondary)
            content()
        }
    }
    
    private func presetButton(preset: ExportConfiguration.Preset) -> some View {
        let isSelected = viewModel.config.selectedPreset == preset
        return Button(action: {
            viewModel.config.selectedPreset = preset
        }) {
            Text(preset.rawValue)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.accentColor : Color.black.opacity(0.2))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.selectedTourID == nil)
    }
}

// MARK: - Theme Preview Card
fileprivate struct ThemePreviewCard: View {
    let theme: ExportConfiguration.CoverPageTheme
    let isSelected: Bool
    
    private let theme1Gradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "3a6073"), Color(hex: "16222a")]),
        startPoint: .top, endPoint: .bottom
    )
    
    var body: some View {
        VStack(spacing: 8) {
            Group {
                switch theme {
                case .theme1:
                    ZStack {
                        theme1Gradient
                        VStack(spacing: 6) {
                            Capsule().frame(width: 40, height: 5).foregroundColor(.white.opacity(0.8))
                            Capsule().frame(width: 60, height: 7).foregroundColor(.white)
                        }
                    }
                case .theme2:
                    VStack(spacing: 0) {
                        theme1Gradient
                        Rectangle().fill(Color.white)
                            .overlay(alignment: .topLeading) { // Correctly align content
                                VStack(alignment: .leading, spacing: 6) {
                                    Capsule().frame(width: 30, height: 5).foregroundColor(.gray.opacity(0.7))
                                    Capsule().frame(width: 70, height: 7).foregroundColor(.black.opacity(0.8))
                                }
                                .padding(12) // Add padding
                            }
                    }
                }
            }
            .frame(width: 120, height: 170) // A4-like aspect ratio
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
            )
            .padding(2)
            
            Text(theme.rawValue)
                .font(.caption)
                .foregroundColor(isSelected ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// Helper for using hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
