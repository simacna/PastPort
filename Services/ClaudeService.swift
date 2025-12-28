//
//  ClaudeService.swift
//  PastPort
//
//  Created by Sina S on 12/28/25.
//

import Foundation
import CoreLocation

class ClaudeService {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func getHistoricalContext(for location: CLLocation) async throws -> String {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        let prompt = """
        You are a friendly and knowledgeable tour guide. The user is currently at coordinates:
        Latitude: \(latitude)
        Longitude: \(longitude)

        Tell them about the historical significance of this location or the nearest notable place.
        Keep your response conversational and engaging, as if you're speaking to them in person.
        Limit your response to 2-3 short paragraphs that can be spoken aloud in about 30-45 seconds.
        Focus on the most interesting historical facts, stories, or cultural significance.
        If this exact location doesn't have notable history, mention the nearest historically significant area.
        """

        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 500,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        guard let url = URL(string: baseURL) else {
            throw ClaudeServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ClaudeServiceError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        let jsonResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let textContent = jsonResponse.content.first?.text else {
            throw ClaudeServiceError.noContent
        }

        return textContent
    }
}

// MARK: - Response Models
struct ClaudeResponse: Codable {
    let content: [ContentBlock]
}

struct ContentBlock: Codable {
    let type: String
    let text: String?
}

// MARK: - Errors
enum ClaudeServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case noContent

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        case .noContent:
            return "No content in response"
        }
    }
}
