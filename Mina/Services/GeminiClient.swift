import Foundation
import UIKit
import ComposableArchitecture

// MARK: - Gemini Client
// TCA Dependency for Gemini API calls.
// Uses Nano Banana Pro (gemini-3-pro-image-preview) for image generation
// and Gemini 3 Pro (gemini-3-pro-image-preview) for text AI features.

struct GeminiClient {
    /// Generate an image from a text prompt using Nano Banana Pro.
    /// Returns raw PNG image data.
    var generateImage: @Sendable (_ prompt: String, _ aspectRatio: String) async throws -> Data
    
    /// Generate text content using Gemini 3 Pro.
    /// Used for AI summaries, story generation, title suggestions, etc.
    var generateText: @Sendable (_ prompt: String) async throws -> String
}

// MARK: - Errors

enum GeminiError: Error, LocalizedError, Equatable {
    case invalidURL
    case invalidAPIKey
    case networkError(String)
    case decodingError(String)
    case noImageInResponse
    case noTextInResponse
    case apiError(String)
    case rateLimited
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidAPIKey:
            return "Invalid or missing API key"
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .noImageInResponse:
            return "No image was returned by the AI model"
        case .noTextInResponse:
            return "No text was returned by the AI model"
        case .apiError(let message):
            return "API error: \(message)"
        case .rateLimited:
            return "Too many requests. Please try again in a moment."
        case .serverError(let code):
            return "Server error (HTTP \(code))"
        }
    }
}

// MARK: - API Response Models

private struct GeminiResponse: Decodable {
    let candidates: [Candidate]?
    let error: APIError?
    
    struct Candidate: Decodable {
        let content: Content?
    }
    
    struct Content: Decodable {
        let parts: [Part]?
    }
    
    struct Part: Decodable {
        let text: String?
        let inlineData: InlineData?
    }
    
    struct InlineData: Decodable {
        let mimeType: String
        let data: String // base64-encoded
    }
    
    struct APIError: Decodable {
        let message: String
        let code: Int?
    }
}

// MARK: - API Request Models

private struct GeminiRequest: Encodable {
    let contents: [RequestContent]
    let generationConfig: GenerationConfig?
    
    struct RequestContent: Encodable {
        let parts: [RequestPart]
    }
    
    struct RequestPart: Encodable {
        let text: String?
        
        enum CodingKeys: String, CodingKey {
            case text
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(text, forKey: .text)
        }
    }
    
    struct GenerationConfig: Encodable {
        let responseModalities: [String]?
        let imageConfig: ImageConfig?
    }
    
    struct ImageConfig: Encodable {
        let aspectRatio: String?
        let imageSize: String?
    }
}

// MARK: - Live Implementation

extension GeminiClient {
    
    private static let imageModelID = "gemini-3-pro-image-preview"
    private static let textModelID = "gemini-3-pro-image-preview" // Same model, text-only modality
    private static let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    
    static func live(apiKey: String) -> Self {
        Self(
            generateImage: { prompt, aspectRatio in
                let url = URL(string: "\(baseURL)/\(imageModelID):generateContent")!
                
                let request = GeminiRequest(
                    contents: [
                        .init(parts: [.init(text: prompt)])
                    ],
                    generationConfig: .init(
                        responseModalities: ["IMAGE"],
                        imageConfig: .init(
                            aspectRatio: aspectRatio,
                            imageSize: "1K"
                        )
                    )
                )
                
                let data = try await performRequest(url: url, body: request, apiKey: apiKey)
                let response = try decodeResponse(data)
                
                // Find the image part in the response
                guard let candidates = response.candidates,
                      let parts = candidates.first?.content?.parts else {
                    throw GeminiError.noImageInResponse
                }
                
                for part in parts {
                    if let inlineData = part.inlineData {
                        guard let imageData = Data(base64Encoded: inlineData.data) else {
                            throw GeminiError.decodingError("Failed to decode base64 image data")
                        }
                        return imageData
                    }
                }
                
                throw GeminiError.noImageInResponse
            },
            
            generateText: { prompt in
                let url = URL(string: "\(baseURL)/\(textModelID):generateContent")!
                
                let request = GeminiRequest(
                    contents: [
                        .init(parts: [.init(text: prompt)])
                    ],
                    generationConfig: .init(
                        responseModalities: ["TEXT"],
                        imageConfig: nil
                    )
                )
                
                let data = try await performRequest(url: url, body: request, apiKey: apiKey)
                let response = try decodeResponse(data)
                
                guard let candidates = response.candidates,
                      let parts = candidates.first?.content?.parts else {
                    throw GeminiError.noTextInResponse
                }
                
                let textParts = parts.compactMap(\.text)
                guard !textParts.isEmpty else {
                    throw GeminiError.noTextInResponse
                }
                
                return textParts.joined(separator: "\n")
            }
        )
    }
    
    // MARK: - Networking Helpers
    
    private static func performRequest(url: URL, body: GeminiRequest, apiKey: String) async throws -> Data {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 120 // Image generation can be slow
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.networkError("Invalid response type")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 429:
            throw GeminiError.rateLimited
        case 400:
            // Try to parse error message
            if let errorResponse = try? JSONDecoder().decode(GeminiResponse.self, from: data),
               let error = errorResponse.error {
                throw GeminiError.apiError(error.message)
            }
            throw GeminiError.apiError("Bad request")
        case 401, 403:
            throw GeminiError.invalidAPIKey
        default:
            if let errorResponse = try? JSONDecoder().decode(GeminiResponse.self, from: data),
               let error = errorResponse.error {
                throw GeminiError.apiError(error.message)
            }
            throw GeminiError.serverError(httpResponse.statusCode)
        }
    }
    
    private static func decodeResponse(_ data: Data) throws -> GeminiResponse {
        let decoder = JSONDecoder()
        do {
            let response = try decoder.decode(GeminiResponse.self, from: data)
            
            // Check for API-level error in the response body
            if let error = response.error {
                throw GeminiError.apiError(error.message)
            }
            
            return response
        } catch let error as GeminiError {
            throw error
        } catch {
            throw GeminiError.decodingError(error.localizedDescription)
        }
    }
}

// MARK: - TCA Dependency

extension GeminiClient: DependencyKey {
    static var liveValue: GeminiClient {
        .live(apiKey: Secrets.geminiAPIKey)
    }
    
    static var testValue: GeminiClient {
        Self(
            generateImage: { _, _ in
                // Return a 1x1 transparent PNG for tests
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
                return renderer.pngData { context in
                    UIColor.systemPurple.setFill()
                    context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
                }
            },
            generateText: { _ in
                "This is a test response from the AI model."
            }
        )
    }
    
    static var previewValue: GeminiClient {
        Self(
            generateImage: { _, _ in
                // Simulate delay and return a colored square
                try await Task.sleep(nanoseconds: 1_500_000_000)
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
                return renderer.pngData { context in
                    let colors: [UIColor] = [.systemPurple, .systemBlue, .systemTeal, .systemPink]
                    let color = colors.randomElement() ?? .systemPurple
                    color.setFill()
                    context.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
                }
            },
            generateText: { _ in
                try await Task.sleep(nanoseconds: 800_000_000)
                return "This month was a journey of self-discovery. You reflected on personal growth, navigated professional challenges, and found moments of gratitude in everyday life."
            }
        )
    }
}

extension DependencyValues {
    var geminiClient: GeminiClient {
        get { self[GeminiClient.self] }
        set { self[GeminiClient.self] = newValue }
    }
}
