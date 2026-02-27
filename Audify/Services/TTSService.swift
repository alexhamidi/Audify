import Foundation


class TTSService {
    static let shared = TTSService()

    private let maxChunkSize = 4000
    private var accessToken: String?
    private var tokenExpiry: Date?
    private var quotaProjectID: String?

    private struct Credentials: Codable {
        let client_id: String
        let client_secret: String
        let refresh_token: String
        let quota_project_id: String?
    }

    private struct TokenResponse: Codable {
        let access_token: String
        let expires_in: Int
    }

    private func getValidToken() async throws -> (token: String, projectID: String?) {
        if let token = accessToken, let expiry = tokenExpiry, expiry > Date() {
            return (token, quotaProjectID)
        }

        guard let url = Bundle.main.url(forResource: "google-credentials", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let creds = try? JSONDecoder().decode(Credentials.self, from: data) else {
            throw TTSError.apiError("Missing or invalid google-credentials.json in bundle")
        }

        self.quotaProjectID = creds.quota_project_id

        var components = URLComponents(string: "https://oauth2.googleapis.com/token")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: creds.client_id),
            URLQueryItem(name: "client_secret", value: creds.client_secret),
            URLQueryItem(name: "refresh_token", value: creds.refresh_token),
            URLQueryItem(name: "grant_type", value: "refresh_token")
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (tokenData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw TTSError.apiError("Failed to refresh token")
        }

        let result = try JSONDecoder().decode(TokenResponse.self, from: tokenData)
        
        self.accessToken = result.access_token
        self.tokenExpiry = Date().addingTimeInterval(Double(result.expires_in) - 60) // buffer of 1 min
        
        return (result.access_token, creds.quota_project_id)
    }

    func synthesizeText(_ text: String, onProgress: ((Double) -> Void)? = nil) async throws -> Data {
        let chunks = self.chunkText(text)
        var audioDatas = [Data?](repeating: nil, count: chunks.count)
        
        // Ensure we have a valid token before starting parallel tasks to avoid multiple refresh calls
        _ = try await self.getValidToken()
        
        try await withThrowingTaskGroup(of: (Int, Data).self) { group in
            let maxConcurrentTasks = 5
            var currentIndex = 0
            var completedCount = 0
            
            // Add initial batch of tasks
            while currentIndex < min(maxConcurrentTasks, chunks.count) {
                let index = currentIndex
                let chunk = chunks[index]
                group.addTask {
                    let data = try await self.synthesizeChunk(chunk)
                    return (index, data)
                }
                currentIndex += 1
            }
            
            // As tasks finish, add more until all chunks are processed
            while let (index, data) = try await group.next() {
                audioDatas[index] = data
                completedCount += 1
                onProgress?(Double(completedCount) / Double(chunks.count))
                
                if currentIndex < chunks.count {
                    let nextIndex = currentIndex
                    let chunk = chunks[nextIndex]
                    group.addTask {
                        let data = try await self.synthesizeChunk(chunk)
                        return (nextIndex, data)
                    }
                    currentIndex += 1
                }
            }
        }
        
        var combinedData = Data()
        for data in audioDatas {
            if let data = data {
                combinedData.append(data)
            }
        }
        
        return combinedData
    }

    private func chunkText(_ text: String) -> [String] {
        var chunks: [String] = []
        var currentChunk = ""
        
        text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .bySentences) { (substring, _, _, _) in
            guard let sentence = substring else { return }
            
            let currentChunkBytes = currentChunk.data(using: .utf8)?.count ?? 0
            let sentenceBytes = sentence.data(using: .utf8)?.count ?? 0
            
            if (currentChunkBytes + sentenceBytes) > self.maxChunkSize {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                    currentChunk = ""
                }
                
                if sentenceBytes > self.maxChunkSize {
                    // Force split long sentence by bytes
                    var remaining = sentence
                    while (remaining.data(using: .utf8)?.count ?? 0) > self.maxChunkSize {
                        // Binary search for safe split point
                        var lower = 0
                        var upper = remaining.count
                        var splitPoint = 0
                        
                        while lower <= upper {
                            let mid = (lower + upper) / 2
                            let subStr = String(remaining.prefix(mid))
                            if (subStr.data(using: .utf8)?.count ?? 0) <= self.maxChunkSize {
                                splitPoint = mid
                                lower = mid + 1
                            } else {
                                upper = mid - 1
                            }
                        }
                        
                        let splitIndex = remaining.index(remaining.startIndex, offsetBy: splitPoint)
                        chunks.append(String(remaining[..<splitIndex]))
                        remaining = String(remaining[splitIndex...])
                    }
                    currentChunk = remaining
                } else {
                    currentChunk = sentence
                }
            } else {
                currentChunk += sentence
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return chunks.isEmpty && !text.isEmpty ? [text] : chunks
    }

    func synthesizeChunk(_ text: String) async throws -> Data {
        let auth = try await self.getValidToken()


        guard let url = URL(string: "https://texttospeech.googleapis.com/v1beta1/text:synthesize") else {
            throw TTSError.apiError("Invalid API URL")
        }


        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(auth.token)", forHTTPHeaderField: "Authorization")
        
        if let projectID = auth.projectID {
            request.setValue(projectID, forHTTPHeaderField: "X-Goog-User-Project")
        }


        let body = TTSRequest(
            input: TTSInput(text: text),
            voice: TTSVoice(languageCode: "en-US", name: "en-US-Chirp3-HD-Achernar"),
            audioConfig: TTSAudioConfig(audioEncoding: "MP3", speakingRate: 1.0)
        )


        request.httpBody = try JSONEncoder().encode(body)


        let (data, response) = try await URLSession.shared.data(for: request)


        guard let httpResponse = response as? HTTPURLResponse else {
            throw TTSError.apiError("Invalid response")
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let error = try JSONDecoder().decode(TTSErrorResponse.self, from: data)
            throw TTSError.apiError(error.error.message)
        }

        let result = try JSONDecoder().decode(TTSResponse.self, from: data)

        guard let audioData = Data(base64Encoded: result.audioContent) else {
            throw TTSError.decodingError
        }

        return audioData
    }
}

