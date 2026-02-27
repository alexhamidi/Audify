import SwiftUI
import PDFKit


struct PDFViewerRepresentable: UIViewRepresentable {
    let url: URL


    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }


    func updateUIView(_ uiView: PDFView, context: Context) {}
}
