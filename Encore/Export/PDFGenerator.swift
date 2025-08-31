import SwiftUI
import CoreGraphics
import AppKit

// This service class handles the conversion of a SwiftUI View to a PDF file.
class PDFGenerator {
    
    @MainActor
    static func generate(view: some View) -> URL? {
        let renderer = ImageRenderer(content: view)
        
        let renderScale: CGFloat = 2.0
        renderer.scale = renderScale
        
        // It's more reliable to work with the CGImage directly for pixel-based operations.
        guard let fullCGImage = renderer.cgImage else {
            print("❌ Failed to render SwiftUI view to a CGImage.")
            return nil
        }
        
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileName = "EncoreExport-\(UUID().uuidString).pdf"
        let url = temporaryDirectory.appendingPathComponent(fileName)
        
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 Page Size
        
        var mediaBox = pageRect
        guard let pdfContext = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            print("❌ Failed to create PDF context.")
            return nil
        }
        
        // --- THIS IS THE FIX ---
        // All calculations are now based on the actual pixel dimensions of the rendered image.
        let totalPixelHeight = CGFloat(fullCGImage.height)
        let totalPixelWidth = CGFloat(fullCGImage.width)
        
        // The height of one page, in pixels.
        let scaledPageHeight = pageRect.height * renderScale
        
        let pageCount = Int(ceil(totalPixelHeight / scaledPageHeight))
        
        for pageIndex in 0..<max(1, pageCount) {
            pdfContext.beginPDFPage(nil)
            
            // Define the slice rectangle in pixels.
            let yOffset = CGFloat(pageIndex) * scaledPageHeight
            let sliceHeight = min(scaledPageHeight, totalPixelHeight - yOffset)
            let rectOfSlice = CGRect(x: 0, y: yOffset, width: totalPixelWidth, height: sliceHeight)
            
            // Crop the full CGImage to get the slice for the current page.
            guard let imageSlice = fullCGImage.cropping(to: rectOfSlice) else {
                pdfContext.endPDFPage()
                continue
            }
            
            // Create an NSImage from the slice with the correct pixel dimensions.
            let sliceImage = NSImage(cgImage: imageSlice, size: NSSize(width: totalPixelWidth, height: sliceHeight))
            
            // Create a blank, full-sized canvas with a perfect A4 aspect ratio at high resolution.
            let canvasSize = NSSize(width: pageRect.width * renderScale, height: pageRect.height * renderScale)
            let canvasImage = NSImage(size: canvasSize)

            // Draw the slice at the top of the blank canvas.
            canvasImage.lockFocus()
            sliceImage.draw(
                at: NSPoint(x: 0, y: canvasSize.height - sliceImage.size.height),
                from: .zero,
                operation: .sourceOver,
                fraction: 1.0
            )
            canvasImage.unlockFocus()

            // Draw the complete, non-distorted canvas image onto the PDF page.
            NSGraphicsContext.saveGraphicsState()
            let nsContext = NSGraphicsContext(cgContext: pdfContext, flipped: false)
            NSGraphicsContext.current = nsContext
            canvasImage.draw(in: pageRect)
            NSGraphicsContext.restoreGraphicsState()
            
            pdfContext.endPDFPage()
        }
        
        pdfContext.closePDF()
        // --- END OF FIX ---
        
        return url
    }
    
    @MainActor
    static func generateAndSave(view: some View, suggestedName: String) {
        guard let tempURL = generate(view: view) else {
            print("❌ Failed to generate temporary PDF.")
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = suggestedName
        savePanel.title = "Save Exported PDF"
        savePanel.prompt = "Save"

        if savePanel.runModal() == .OK {
            if let destinationURL = savePanel.url {
                do {
                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    try fileManager.moveItem(at: tempURL, to: destinationURL)
                    print("✅ PDF saved successfully to: \(destinationURL.path)")
                } catch {
                    print("❌ Error saving PDF: \(error.localizedDescription)")
                }
            }
        }
    }
}
