import SwiftUI
import CoreGraphics
import AppKit

// This service class handles the conversion of a SwiftUI View to a PDF file.
class PDFGenerator {
    
    @MainActor
    static func generate(view: some View) -> URL? {
        let renderer = ImageRenderer(content: view)
        
        // Create a temporary file URL
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileName = "EncoreExport-\(UUID().uuidString).pdf"
        let url = temporaryDirectory.appendingPathComponent(fileName)
        
        renderer.render { size, context in
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            
            guard var pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
                return
            }
            
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }
        
        return url
    }
    
    // New function to handle the "Save As..." dialog
    @MainActor
    static func generateAndSave(view: some View, suggestedName: String) {
        // First, generate the PDF to a temporary location
        guard let tempURL = generate(view: view) else {
            print("❌ Failed to generate temporary PDF.")
            return
        }
        
        // Create and configure the save panel
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = suggestedName
        savePanel.title = "Save Exported PDF"
        savePanel.prompt = "Save"

        // Show the panel and handle the result
        if savePanel.runModal() == .OK {
            if let destinationURL = savePanel.url {
                do {
                    let fileManager = FileManager.default
                    // If a file already exists at the destination, remove it first
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    // Move the temporary file to the user's chosen destination
                    try fileManager.moveItem(at: tempURL, to: destinationURL)
                    print("✅ PDF saved successfully to: \(destinationURL.path)")
                } catch {
                    print("❌ Error saving PDF: \(error.localizedDescription)")
                }
            }
        }
    }
}
