import SwiftUI
import Kingfisher

struct LandingPageConfigView: View {
    @StateObject private var viewModel: LandingPageViewModel
    @Environment(\.dismiss) var dismiss
    
    // States for image picker
    @State private var headerImage: NSImage?
    @State private var headerImageURL: URL?

    init(tour: Tour) {
        _viewModel = StateObject(wrappedValue: LandingPageViewModel(tour: tour))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    imageUploader
                    urlConfiguration
                }
                .padding(30)
            }
            
            Spacer()
            footer
        }
        .frame(minWidth: 700, minHeight: 700)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Landing Page")
                    .font(.largeTitle.bold())
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            Text("Customize the public web page where fans can view all shows and buy tickets.")
                .foregroundColor(.secondary)
        }
        .padding([.top, .horizontal], 30)
        .padding(.bottom)
    }
    
    private var imageUploader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Header Image").font(.headline)
            
            ZStack {
                if let image = headerImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if let urlString = viewModel.tour.landingPageHeaderImageUrl, let url = URL(string: urlString) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle().fill(Material.regular)
                    VStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.largeTitle)
                        Text("Click to upload a header image (1500x500 recommended)")
                    }
                    .foregroundColor(.secondary)
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture(perform: selectHeaderImage)
        }
    }
    
    private var urlConfiguration: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom URL").font(.headline)
            
            // FIX: Replaced invalid cornerRadius modifier with .clipShape on the parent HStack
            HStack(spacing: 0) {
                Text("en-co.re/t/")
                    .font(.headline)
                    .padding(12)
                    .background(Color.black.opacity(0.15))
                
                TextField("your-tour-name", text: $viewModel.urlSlug)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(Color.black.opacity(0.25))
                    .onChange(of: viewModel.urlSlug) {
                        viewModel.checkUrlAvailability()
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))

            
            HStack {
                switch viewModel.availabilityStatus {
                case .idle: Text("").font(.caption)
                case .checking: ProgressView().scaleEffect(0.5)
                case .available:
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("Available!").foregroundColor(.green)
                case .unavailable(let msg):
                    Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                    Text(msg).foregroundColor(.red)
                case .error(let msg):
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    Text(msg).foregroundColor(.orange)
                }
                Spacer()
            }
            .font(.caption)
            .frame(height: 20)
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Publish Later") {
                Task {
                    await viewModel.saveAndPublish(headerImageUrl: headerImageURL, publishNow: false)
                    dismiss()
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            
            Button("Publish Tickets") {
                Task {
                    await viewModel.saveAndPublish(headerImageUrl: headerImageURL, publishNow: true)
                    dismiss()
                }
            }
            .buttonStyle(PrimaryButtonStyle(color: .green, isLoading: viewModel.isSaving))
            .disabled(viewModel.availabilityStatus != .available || viewModel.isSaving)
        }
        .padding()
        .background(Material.bar)
    }

    private func selectHeaderImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.jpeg, .png]
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url, let image = NSImage(contentsOf: url) {
            self.headerImage = image
            self.headerImageURL = url
        }
    }
}
