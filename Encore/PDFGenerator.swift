import SwiftUI
import CoreGraphics

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
}
