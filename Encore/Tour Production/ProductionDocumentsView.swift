import SwiftUI

struct ProductionDocumentsView: View {
    @StateObject private var viewModel: ProductionDocumentsViewModel
    
    // State for the file importer sheet
    @State private var showingFileImporter = false
    @State private var documentNameToAdd = ""
    @State private var documentTypeToAdd = "Tech Rider"
    @State private var selectedURL: URL?

    let documentTypes = ["Tech Rider", "Stage Plot", "Venue Specs", "Hospitality Rider", "Other"]

    init(tour: Tour) {
        _viewModel = StateObject(wrappedValue: ProductionDocumentsViewModel(tour: tour))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Technical Documents").font(.headline)
                Spacer()
                Button(action: {
                    self.documentNameToAdd = ""
                    self.showingFileImporter = true
                }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.isUploading)
            }
            
            if viewModel.isUploading {
                VStack {
                    ProgressView(value: viewModel.uploadProgress)
                    Text("Uploading... \(Int(viewModel.uploadProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if viewModel.documents.isEmpty {
                Text("No documents have been uploaded for this tour.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.documents) { doc in
                    documentRow(doc)
                }
            }
        }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.pdf, .png, .jpeg]) { result in
            switch result {
            case .success(let url):
                self.selectedURL = url
                self.documentNameToAdd = url.deletingPathExtension().lastPathComponent
            case .failure(let error):
                print("Error picking file: \(error.localizedDescription)")
            }
        }
        .sheet(item: $selectedURL) { url in
            uploadDetailsSheet(for: url)
        }
    }
    
    private func documentRow(_ doc: ProductionDocument) -> some View {
        HStack {
            Image(systemName: icon(for: doc.fileType))
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(doc.name).fontWeight(.medium)
                Text(doc.type).font(.caption).foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                if let url = URL(string: doc.fileURL) {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Image(systemName: "arrow.down.circle")
            }
            .buttonStyle(.plain)
            
            Button(role: .destructive, action: {
                Task { await viewModel.deleteDocument(doc) }
            }) {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Material.regular.opacity(0.5))
        .cornerRadius(12)
    }
    
    private func uploadDetailsSheet(for url: URL) -> some View {
        VStack(spacing: 20) {
            Text("Upload Document").font(.title2.bold())
            
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading) {
                Text("File Name").font(.headline)
                StyledInputField(placeholder: "Enter a name for the document", text: $documentNameToAdd)
            }
            
            VStack(alignment: .leading) {
                Text("Document Type").font(.headline)
                Picker("Type", selection: $documentTypeToAdd) {
                    ForEach(documentTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await viewModel.uploadDocument(fileURL: url, documentName: documentNameToAdd, documentType: documentTypeToAdd)
                    self.selectedURL = nil
                }
            }) {
                Text("Upload and Save")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .disabled(documentNameToAdd.isEmpty)
        }
        .padding(30)
        .frame(width: 400, height: 450)
    }
    
    private func icon(for fileType: String) -> String {
        switch fileType.lowercased() {
        case "pdf":
            return "doc.text.fill"
        case "png", "jpeg", "jpg":
            return "photo.fill"
        default:
            return "doc.fill"
        }
    }
}

// Helper to make URL identifiable for sheets
extension URL: Identifiable {
    public var id: String { self.absoluteString }
}
