import SwiftUI

// This is a reusable UI component.
struct ExportShowTimingButton: View {
    // FIX: Updated to use the new 'Show' and 'Tour' models.
    let show: Show
    let tour: Tour

    @State private var pdfURL: URL?
    @State private var isSharing = false
    @State private var isProcessing = false

    var body: some View {
        Button(action: generateAndSharePDF) {
            if isProcessing {
                ProgressView()
            } else {
                HStack {
                    Image(systemName: "doc.text")
                    Text("Export Show Times")
                }
            }
        }
        .disabled(isProcessing)
        .sharingSheet(isPresented: $isSharing, items: [pdfURL].compactMap { $0 })
    }

    private func generateAndSharePDF() {
        isProcessing = true
        
        Task {
            // This now passes the new model types to the PDF renderer.
            // This will cause a new error in 'ShowTimingPDFView' which we will fix later.
            let viewToRender = ShowTimingPDFView(show: show, tour: tour)
            let url = await PDFGenerator.generate(view: viewToRender)
            
            await MainActor.run {
                self.pdfURL = url
                self.isSharing = url != nil
                self.isProcessing = false
            }
        }
    }
}

// NOTE: The sharingSheet extension and its related components remain unchanged.
// They are correct as they are.
extension View {
    func sharingSheet(isPresented: Binding<Bool>, items: [Any]) -> some View {
        self.modifier(SharingSheet(isPresented: isPresented, items: items))
    }
}

private struct SharingSheet: ViewModifier {
    @Binding var isPresented: Bool
    let items: [Any]

    func body(content: Content) -> some View {
        content
            .background(SharingSheetPresenter(isPresented: $isPresented, items: items))
    }
}

private struct SharingSheetPresenter: NSViewRepresentable {
    @Binding var isPresented: Bool
    let items: [Any]

    func makeNSView(context: Context) -> NSView {
        return NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if isPresented {
            let picker = NSSharingServicePicker(items: items)
            picker.delegate = context.coordinator
            
            DispatchQueue.main.async {
                picker.show(relativeTo: .zero, of: nsView, preferredEdge: .minY)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSSharingServicePickerDelegate {
        var parent: SharingSheetPresenter
        
        init(_ parent: SharingSheetPresenter) {
            self.parent = parent
        }
        
        func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?, error: Error?) {
            parent.isPresented = false
        }
    }
}
