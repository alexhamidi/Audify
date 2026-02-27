import SwiftUI
import SwiftData
import PDFKit

@Observable
class LibraryViewModel {
    var showError: Bool = false
    var errorMessage: String = ""
    var showFilePicker: Bool = false
    var showSearchView: Bool = false
    
    var searchResults: [ExaResult] = []
    var isSearching: Bool = false
    var isImporting: Bool = false
    
    func searchPDFs(query: String) {
        isSearching = true
        searchResults = []
        
        Task {
            do {
                let results = try await ExaService.shared.searchPDFs(query: query)
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.showErrorAlert("Search failed: \(error.localizedDescription)")
                    self.isSearching = false
                }
            }
        }
    }
    
    func importFromURL(_ url: URL, modelContext: ModelContext) {
        isImporting = true
        print("Importing PDF from URL: \(url)")
        
        Task {
            do {
                let (tempURL, response) = try await URLSession.shared.download(from: url)
                
                // Validate response
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    print("Import Error: HTTP \(httpResponse.statusCode)")
                    throw NSError(domain: "Import", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned error \(httpResponse.statusCode)"])
                }
                
                // Ensure it's a PDF
                if let mimeType = response.mimeType, mimeType != "application/pdf" {
                    if !url.pathExtension.lowercased().contains("pdf") {
                        print("Import Error: Not a PDF (MIME: \(mimeType ?? "unknown"))")
                        throw NSError(domain: "Import", code: 0, userInfo: [NSLocalizedDescriptionKey: "Selected file is not a valid PDF."])
                    }
                }
                
                let fileName = UUID().uuidString + ".pdf"
                let destination = getDocumentsDirectory().appendingPathComponent(fileName)
                try FileManager.default.copyItem(at: tempURL, to: destination)
                print("Imported PDF saved to: \(destination.path)")
                
                await MainActor.run {
                    guard let pdfDocument = PDFDocument(url: destination) else {
                        print("Import Error: Could not open PDFDocument")
                        showErrorAlert("Unable to read the downloaded PDF.")
                        isImporting = false
                        return
                    }
                    
                    print("PDF successfully opened for import. Pages: \(pdfDocument.pageCount)")
                    var rawText = ""
                    for i in 0..<pdfDocument.pageCount {
                        if let page = pdfDocument.page(at: i), let text = page.string {
                            rawText += text + " "
                        }
                    }
                    
                    let joinedText = rawText.replacingOccurrences(of: "\n", with: " ")
                    let extractedText = joinedText.replacingOccurrences(of: " +", with: " ", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let title = url.deletingPathExtension().lastPathComponent
                    let document = AudioDocument(title: title, pdfFileName: fileName, extractedText: extractedText)
                    modelContext.insert(document)
                    
                    print("Document inserted into database: \(title)")
                    isImporting = false
                    generateAudio(for: document)
                }
            } catch {
                print("Import Final Error: \(error.localizedDescription)")
                await MainActor.run {
                    showErrorAlert("Failed to download PDF: \(error.localizedDescription)")
                    isImporting = false
                }
            }
        }
    }

    func importPDF(from result: Result<URL, Error>, modelContext: ModelContext) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                showErrorAlert("Unable to access the file.")
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let pdfDocument = PDFDocument(url: url) else {
                showErrorAlert("Unable to read the PDF.")
                return
            }

            var rawText = ""
            for i in 0..<pdfDocument.pageCount {
                if let page = pdfDocument.page(at: i), let text = page.string {
                    rawText += text + " "
                }
            }
            
            let joinedText = rawText.replacingOccurrences(of: "\n", with: " ")
            let extractedText = joinedText.replacingOccurrences(of: " +", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                showErrorAlert("No readable text found in this PDF.")
                return
            }

            let title = url.deletingPathExtension().lastPathComponent
            let fileName = UUID().uuidString + ".pdf"
            let destination = getDocumentsDirectory().appendingPathComponent(fileName)

            do {
                try FileManager.default.copyItem(at: url, to: destination)
                let document = AudioDocument(title: title, pdfFileName: fileName, extractedText: extractedText)
                modelContext.insert(document)
                
                generateAudio(for: document)
            } catch {
                showErrorAlert("Failed to save the PDF.")
            }

        case .failure(let error):
            showErrorAlert(error.localizedDescription)
        }
    }

    func deleteDocument(_ document: AudioDocument, modelContext: ModelContext) {
        if let pdfURL = document.pdfURL {
            try? FileManager.default.removeItem(at: pdfURL)
        }
        if let audioURL = document.audioURL {
            try? FileManager.default.removeItem(at: audioURL)
        }
        if let imageURL = document.imageURL {
            try? FileManager.default.removeItem(at: imageURL)
        }
        modelContext.delete(document)
    }

    func generateAudio(for document: AudioDocument) {
        document.isProcessing = true
        document.errorMessage = nil
        document.processingProgress = 0

        Task {
            do {
                let text = document.extractedText
                
                async let metadataTask = MetadataService.shared.extractMetadata(from: text)
                async let audioDataTask = TTSService.shared.synthesizeText(text) { progress in
                    Task { @MainActor in
                        document.processingProgress = progress
                    }
                }
                
                let metadata = try await metadataTask
                
                let imagePrompt = "\(metadata.title) by \(metadata.author)"
                async let imageDataTask = ImageGenerationService.shared.generateImage(for: imagePrompt)
                
                let (audioData, imageData) = try await (audioDataTask, imageDataTask)
                
                let audioFileName = UUID().uuidString + ".mp3"
                let audioDestination = getDocumentsDirectory().appendingPathComponent(audioFileName)
                try audioData.write(to: audioDestination)
                
                let imageFileName = UUID().uuidString + ".jpg"
                let imageDestination = getDocumentsDirectory().appendingPathComponent(imageFileName)
                try imageData.write(to: imageDestination)
                
                await MainActor.run {
                    document.title = metadata.title
                    document.author = metadata.author
                    document.audioFileName = audioFileName
                    document.imageFileName = imageFileName
                    document.isProcessing = false
                    document.processingProgress = 1.0
                }
            } catch {
                await MainActor.run {
                    document.errorMessage = error.localizedDescription
                    document.isProcessing = false
                }
            }
        }
    }

    private func showErrorAlert(_ message: String) {
        errorMessage = message
        showError = true
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
