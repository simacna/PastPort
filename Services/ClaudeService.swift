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
    private let geocoder = CLGeocoder()

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func getHistoricalContext(for location: CLLocation) async throws -> String {
        // Step 1: Reverse geocode to get place name hierarchy
        let placeInfo = await reverseGeocode(location: location)

        // Step 2: Build prompt with place hierarchy and fallback instructions
        let prompt = buildPrompt(placeInfo: placeInfo, location: location)

        // Step 3: Call Claude API
        return try await callClaudeAPI(prompt: prompt)
    }

    private func reverseGeocode(location: CLLocation) async -> PlaceInfo {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else {
                return PlaceInfo(coordinates: location.coordinate)
            }

            return PlaceInfo(
                streetAddress: [placemark.subThoroughfare, placemark.thoroughfare]
                    .compactMap { $0 }
                    .joined(separator: " "),
                neighborhood: placemark.subLocality,
                city: placemark.locality,
                state: placemark.administrativeArea,
                country: placemark.country,
                coordinates: location.coordinate
            )
        } catch {
            return PlaceInfo(coordinates: location.coordinate)
        }
    }

    private func buildPrompt(placeInfo: PlaceInfo, location: CLLocation) -> String {
        var locationDescription = ""

        if let street = placeInfo.streetAddress, !street.isEmpty {
            locationDescription += "Street: \(street)\n"
        }
        if let neighborhood = placeInfo.neighborhood {
            locationDescription += "Neighborhood: \(neighborhood)\n"
        }
        if let city = placeInfo.city {
            locationDescription += "City: \(city)\n"
        }
        if let state = placeInfo.state {
            locationDescription += "State/Region: \(state)\n"
        }
        if let country = placeInfo.country {
            locationDescription += "Country: \(country)\n"
        }

        locationDescription += "Coordinates: \(location.coordinate.latitude), \(location.coordinate.longitude)"

        return """
        You are a friendly and knowledgeable tour guide speaking to someone at this location:

        \(locationDescription)

        Your task:
        1. FIRST, try to share historical facts about this exact street or address if notable.
        2. If nothing notable at the exact spot, expand to the neighborhood and share its history.
        3. If the neighborhood has limited history, expand to the city or district level.
        4. As a last resort, share the most interesting nearby historical site or a fascinating local fact.

        Guidelines:
        - Keep your response conversational, as if speaking in person
        - Limit to 2-3 short paragraphs (30-45 seconds when spoken aloud)
        - Focus on the most captivating stories, not dry facts
        - Always give the user SOMETHING interesting — never say "there's nothing here"
        - Start by telling them what place you're describing
        """
    }

    private func callClaudeAPI(prompt: String) async throws -> String {
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

// MARK: - Place Info
struct PlaceInfo {
    var streetAddress: String?
    var neighborhood: String?
    var city: String?
    var state: String?
    var country: String?
    var coordinates: CLLocationCoordinate2D

    init(
        streetAddress: String? = nil,
        neighborhood: String? = nil,
        city: String? = nil,
        state: String? = nil,
        country: String? = nil,
        coordinates: CLLocationCoordinate2D
    ) {
        self.streetAddress = streetAddress
        self.neighborhood = neighborhood
        self.city = city
        self.state = state
        self.country = country
        self.coordinates = coordinates
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
