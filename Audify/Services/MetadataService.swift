import Foundation

struct MetadataResponse: Codable {
    let title: String
    let author: String
}

class MetadataService {
    static let shared = MetadataService()
    
    private let apiKey = "YOUR_OPENROUTER_API_KEY"
    
    func extractMetadata(from text: String) async throws -> MetadataResponse {
        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            throw NSError(domain: "MetadataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Audify", forHTTPHeaderField: "HTTP-Referer") // OpenRouter requirement
        
        // Take first 2000 characters for metadata extraction to save tokens and speed up
        let sampleText = String(text.prefix(2000))
        
        let prompt = """
        Extract the book title and author name from the following text. 
        Return ONLY a JSON object with keys "title" and "author".
        If you cannot find the author, use "Unknown".
        
        Text:
        \(sampleText)
        """
        
        let body: [String: Any] = [
            "model": "arcee-ai/trinity-large-preview:free",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "response_format": ["type": "json_object"]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "MetadataService", code: 1, userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorMsg)"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let content = choices?.first?["message"] as? [String: Any]
        let contentString = content?["content"] as? String ?? ""
        
        guard let contentData = contentString.data(using: .utf8) else {
            throw NSError(domain: "MetadataService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Decoding Error"])
        }
        
        return try JSONDecoder().decode(MetadataResponse.self, from: contentData)
    }
}
