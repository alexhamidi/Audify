import Foundation

struct ExaResult: Codable, Identifiable {
    let id: String
    let url: String
    let title: String?
    let score: Double?
}

struct ExaSearchResponse: Codable {
    let results: [ExaResult]
}

class ExaService {
    static let shared = ExaService()
    
    private let apiKey = "YOUR_EXA_API_KEY"
    private let endpoint = "https://api.exa.ai/search"
    
    func searchPDFs(query: String) async throws -> [ExaResult] {
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "ExaService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Exa allows filtering by file type in the query or via parameters
        // Using contents: { text: true } to get some snippet if needed, but results for now
        let body: [String: Any] = [
            "query": query,
            "category": "pdf",
            "useAutoprompt": true,
            "numResults": 30
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ExaService", code: 1, userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorMsg)"])
        }
        
        let decoder = JSONDecoder()
        let searchResponse = try decoder.decode(ExaSearchResponse.self, from: data)
        
        // Filter to prioritize direct PDF links
        return searchResponse.results.filter { $0.url.lowercased().contains("pdf") || $0.url.lowercased().hasSuffix(".pdf") }
    }
}
