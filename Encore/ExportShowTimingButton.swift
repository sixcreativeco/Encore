import SwiftUI

// This is a reusable UI component.
// You can place this button in any view that has access to a `show` and `tour` object.

struct ExportShowTimingButton: View {
    let show: ShowModel
    let tour: TourModel

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

// You will also need to add this sharingSheet modifier extension to your project,
// for example in a new file called 'View+SharingSheet.swift'.
// This is required to present the share sheet on macOS.

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
            
            // We need to show the picker relative to a view.
            // Using a slight delay ensures the view hierarchy is stable.
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
            // Dismiss the sheet after a selection or cancellation.
            parent.isPresented = false
        }
    }
}
