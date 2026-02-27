import Foundation

class ImageGenerationService {
    static let shared = ImageGenerationService()
    
    private let endpoint = "https://free-image-generation.alextheastro.workers.dev/"
    private let authHeader = "Bearer YOUR_IMAGE_GEN_TOKEN"
    
    func generateImage(for prompt: String) async throws -> Data {
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "ImageGenerationService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "prompt": prompt
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ImageGenerationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ImageGenerationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "API Error: \(httpResponse.statusCode) - \(errorMsg)"])
        }
        
        return data
    }
}
