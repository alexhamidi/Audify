import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let url: URL
    let onUse: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var localURL: URL?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Downloading PDF for preview...")
                            .foregroundStyle(.secondary)
                    }
                } else if let localURL = localURL {
                    PDFViewerRepresentable(url: localURL)
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        ContentUnavailableView("Preview Failed", systemImage: "exclamationmark.triangle", description: Text(error))
                        
                        Button {
                            if let safariURL = URL(string: url.absoluteString) {
                                UIApplication.shared.open(safariURL)
                            }
                        } label: {
                            Label("Open in Safari", systemImage: "safari")
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Retry") {
                            isLoading = true
                            errorMessage = nil
                            downloadPDF()
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                    }
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Use PDF") {
                        onUse()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(localURL == nil)
                }
            }
        }
        .onAppear {
            downloadPDF()
        }
    }

    private func downloadPDF() {
        print("Starting PDF download for preview from: \(url)")
        Task {
            do {
                let (tempURL, response) = try await URLSession.shared.download(from: url)
                
                // Validate response
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "PDFDownload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
                }
                
                print("Download response status code: \(httpResponse.statusCode)")
                
                if !(200...299).contains(httpResponse.statusCode) {
                    throw NSError(domain: "PDFDownload", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned error code \(httpResponse.statusCode)"])
                }
                
                // Copy to a more stable temp location with .pdf extension for PDFKit
                let permanentTempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("pdf")
                
                try FileManager.default.moveItem(at: tempURL, to: permanentTempURL)
                print("PDF downloaded and moved to: \(permanentTempURL.path)")
                
                // Final check - try to open as PDFDocument
                guard let doc = PDFDocument(url: permanentTempURL) else {
                    print("Failed to initialize PDFDocument from downloaded file.")
                    throw NSError(domain: "PDFDownload", code: 0, userInfo: [NSLocalizedDescriptionKey: "Downloaded file is not a valid PDF."])
                }
                
                print("PDF successfully opened. Page count: \(doc.pageCount)")
                
                await MainActor.run {
                    self.localURL = permanentTempURL
                    self.isLoading = false
                }
            } catch {
                print("PDF Preview Error: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
