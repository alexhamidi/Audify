import Foundation


struct TTSRequest: Codable, Sendable {
    let input: TTSInput
    let voice: TTSVoice
    let audioConfig: TTSAudioConfig
}


struct TTSInput: Codable, Sendable {
    let text: String
}


struct TTSVoice: Codable, Sendable {
    let languageCode: String
    let name: String
}


struct TTSAudioConfig: Codable, Sendable {
    let audioEncoding: String
    let speakingRate: Double
}


struct TTSResponse: Codable, Sendable {
    let audioContent: String
}


struct TTSErrorResponse: Codable, Sendable {
    let error: TTSErrorDetail
}


struct TTSErrorDetail: Codable, Sendable {
    let code: Int
    let message: String
    let status: String
}


enum TTSError: Error, LocalizedError, Sendable {
    case noAPIKey
    case apiError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "Google TTS API Key is missing."
        case .apiError(let message): return message
        case .decodingError: return "Failed to decode the TTS response."
        }
    }
}

