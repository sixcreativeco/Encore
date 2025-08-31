import SwiftUI
import Kingfisher

struct StagePlotView: View {
    @StateObject private var viewModel: StagePlotViewModel
    
    // This binding ensures that when a new URL is uploaded, the parent view (ProductionTabView) is also updated.
    @Binding var tour: Tour
    
    @State private var showingFileImporter = false

    init(tour: Binding<Tour>) {
        self._tour = tour
        self._viewModel = StateObject(wrappedValue: StagePlotViewModel(tour: tour))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stage Plot").font(.headline)
            
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.regular.opacity(0.5))

                // Content
                if let urlString = viewModel.tour.stagePlotImageURL, let url = URL(string: urlString) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8)
                } else {
                    placeholderView
                }
                
                // Progress overlay
                if viewModel.isUploading {
                    VStack(spacing: 8) {
                        ProgressView(value: viewModel.uploadProgress)
                        Text("Uploading...")
                            .font(.caption)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(10)
                }
            }
            .frame(height: 300)
            .onTapGesture {
                showingFileImporter = true
            }
            
            if viewModel.tour.stagePlotImageURL != nil {
                HStack {
                    Button("Replace Image") { showingFileImporter = true }
                    Spacer()
                    Button("Delete", role: .destructive) { Task { await viewModel.deleteStagePlot() } }
                }
                .buttonStyle(.plain)
                .font(.caption)
            }
        }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.image, .pdf]) { result in
            switch result {
            case .success(let url):
                Task {
                    await viewModel.uploadStagePlot(fileURL: url)
                }
            case .failure(let error):
                print("Error picking file for stage plot: \(error.localizedDescription)")
            }
        }
    }
    
    private var placeholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
            Text("Click to Upload Stage Plot")
                .font(.headline)
            Text("Images and PDFs are supported.")
                .font(.subheadline)
        }
        .foregroundColor(.secondary)
    }
}
