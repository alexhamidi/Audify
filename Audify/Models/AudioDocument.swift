import SwiftData
import Foundation


@Model
final class AudioDocument {
    var id: UUID
    var title: String
    var author: String?
    var dateAdded: Date
    var pdfFileName: String
    var audioFileName: String?
    var imageFileName: String?
    var extractedText: String
    var isProcessing: Bool
    var processingProgress: Double
    var errorMessage: String?
    var lastPlaybackPosition: TimeInterval = 0


    init(title: String, pdfFileName: String, extractedText: String) {
        self.id = UUID()
        self.title = title
        self.author = nil
        self.dateAdded = Date()
        self.pdfFileName = pdfFileName
        self.extractedText = extractedText
        self.isProcessing = false
        self.processingProgress = 0
        self.lastPlaybackPosition = 0
    }


    var pdfURL: URL? {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return docs.appendingPathComponent(pdfFileName)
    }


    var audioURL: URL? {
        guard let audioFileName else { return nil }
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return docs.appendingPathComponent(audioFileName)
    }

    var imageURL: URL? {
        guard let imageFileName else { return nil }
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return docs.appendingPathComponent(imageFileName)
    }

    var isReady: Bool {
        audioFileName != nil
    }
}
