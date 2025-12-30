//
//  IntegrationTests.swift
//  PastPortTests
//
//  Created by Sina S on 12/28/25.
//
//  NOTE: These tests require a valid Claude API key set in the environment
//  variable CLAUDE_API_KEY or passed directly to the test.
//
//  To run: Set CLAUDE_API_KEY in your scheme's environment variables
//

import XCTest
import CoreLocation
@testable import PastPort

final class IntegrationTests: XCTestCase {

    var apiKey: String?

    override func setUp() {
        super.setUp()
        // Try to get API key from environment
        apiKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"]
    }

    // MARK: - Claude API Integration Test

    /// Smoke test that hits the real Claude API
    /// Skip if no API key is available
    func testClaudeAPIIntegration() async throws {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw XCTSkip("CLAUDE_API_KEY not set - skipping integration test")
        }

        let service = ClaudeService(apiKey: apiKey)
        let timesSquare = CLLocation(latitude: 40.7580, longitude: -73.9855)

        let response = try await service.getHistoricalContext(for: timesSquare)

        // Verify we got a non-empty response
        XCTAssertFalse(response.isEmpty, "Response should not be empty")

        // Verify response has reasonable length (30-45 seconds of speech ~ 75-110 words ~ 400-700 chars)
        XCTAssertGreaterThan(response.count, 100, "Response should be substantial")
        XCTAssertLessThan(response.count, 2000, "Response should not be too long")

        // Print for manual verification
        print("--- Claude Response for Times Square ---")
        print(response)
        print("--- End Response ---")
    }

    /// Test that the API returns appropriate error for invalid key
    func testClaudeAPIInvalidKey() async {
        let service = ClaudeService(apiKey: "invalid-api-key")
        let location = CLLocation(latitude: 40.7580, longitude: -73.9855)

        do {
            _ = try await service.getHistoricalContext(for: location)
            XCTFail("Should have thrown an error for invalid API key")
        } catch let error as ClaudeServiceError {
            if case .apiError(let statusCode, _) = error {
                // Expect 401 Unauthorized or 403 Forbidden
                XCTAssertTrue(
                    statusCode == 401 || statusCode == 403,
                    "Expected 401 or 403, got \(statusCode)"
                )
            } else {
                // Other ClaudeServiceError is also acceptable
                XCTAssertNotNil(error.errorDescription)
            }
        } catch {
            // Network errors are acceptable in CI environments
            print("Network error (acceptable): \(error)")
        }
    }

    // MARK: - Reverse Geocoding Integration Test

    /// Test that reverse geocoding works for a known location
    func testReverseGeocodingIntegration() async throws {
        let geocoder = CLGeocoder()
        let timesSquare = CLLocation(latitude: 40.7580, longitude: -73.9855)

        let placemarks = try await geocoder.reverseGeocodeLocation(timesSquare)

        XCTAssertFalse(placemarks.isEmpty, "Should return at least one placemark")

        if let placemark = placemarks.first {
            // Times Square should be in New York
            XCTAssertEqual(placemark.locality, "New York")
            XCTAssertEqual(placemark.administrativeArea, "NY")
            XCTAssertEqual(placemark.country, "United States")

            print("--- Placemark for Times Square ---")
            print("Street: \(placemark.thoroughfare ?? "N/A")")
            print("Neighborhood: \(placemark.subLocality ?? "N/A")")
            print("City: \(placemark.locality ?? "N/A")")
            print("State: \(placemark.administrativeArea ?? "N/A")")
            print("Country: \(placemark.country ?? "N/A")")
            print("--- End Placemark ---")
        }
    }

    // MARK: - End-to-End Flow Test

    /// Full integration test: Location -> Geocode -> Claude -> Verify
    func testEndToEndFlow() async throws {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw XCTSkip("CLAUDE_API_KEY not set - skipping integration test")
        }

        // 1. Create a location (Statue of Liberty)
        let statueOfLiberty = CLLocation(latitude: 40.6892, longitude: -74.0445)

        // 2. Create Claude service
        let claudeService = ClaudeService(apiKey: apiKey)

        // 3. Get historical context (this includes geocoding internally)
        let response = try await claudeService.getHistoricalContext(for: statueOfLiberty)

        // 4. Verify response mentions relevant content
        XCTAssertFalse(response.isEmpty)

        // The response should likely mention Liberty, statue, or New York
        let lowercaseResponse = response.lowercased()
        let relevantTerms = ["liberty", "statue", "new york", "harbor", "island", "monument", "french", "immigrant"]
        let containsRelevantTerm = relevantTerms.contains { lowercaseResponse.contains($0) }

        XCTAssertTrue(
            containsRelevantTerm,
            "Response should mention relevant historical terms for Statue of Liberty"
        )

        print("--- End-to-End Test: Statue of Liberty ---")
        print(response)
        print("--- End Response ---")
    }
}
