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
                        case .date:
                            dateConfiguration()
                        default:
                            configSection(title: "Preferences") {
                                Text("This preset is not yet configured.")
                                    .foregroundColor(.secondary)
                            }
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
            VStack(alignment: .leading, spacing: 12) {
                Text("Preview").font(.headline).foregroundColor(.secondary)
                
                if viewModel.isLoading && viewModel.selectedTourID != nil {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let previewImage = viewModel.previewImage {
                    Image(nsImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.1))
                        .overlay(Text("Select a tour and preset to see a preview.").foregroundColor(.secondary))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func tourSelector() -> some View {
        configSection(title: "Tour") {
            Menu {
                ForEach(viewModel.tours) { tour in
                    Button(tour.tourName) {
                        viewModel.selectedTourID = tour.id
                    }
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
