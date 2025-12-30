//
//  ClaudeServiceTests.swift
//  PastPortTests
//
//  Created by Sina S on 12/28/25.
//

import XCTest
import CoreLocation
@testable import PastPort

final class ClaudeServiceTests: XCTestCase {

    var sut: ClaudeService!

    override func setUp() {
        super.setUp()
        sut = ClaudeService(apiKey: "test-api-key")
    }

    override func tearDown() {
        sut = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    // MARK: - PlaceInfo Tests

    func testPlaceInfoInitializesWithAllFields() {
        let coordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        let placeInfo = PlaceInfo(
            streetAddress: "123 Main St",
            neighborhood: "Financial District",
            city: "New York",
            state: "NY",
            country: "USA",
            coordinates: coordinate
        )

        XCTAssertEqual(placeInfo.streetAddress, "123 Main St")
        XCTAssertEqual(placeInfo.neighborhood, "Financial District")
        XCTAssertEqual(placeInfo.city, "New York")
        XCTAssertEqual(placeInfo.state, "NY")
        XCTAssertEqual(placeInfo.country, "USA")
        XCTAssertEqual(placeInfo.coordinates.latitude, 40.7128)
        XCTAssertEqual(placeInfo.coordinates.longitude, -74.0060)
    }

    func testPlaceInfoInitializesWithMinimalFields() {
        let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let placeInfo = PlaceInfo(coordinates: coordinate)

        XCTAssertNil(placeInfo.streetAddress)
        XCTAssertNil(placeInfo.neighborhood)
        XCTAssertNil(placeInfo.city)
        XCTAssertNil(placeInfo.state)
        XCTAssertNil(placeInfo.country)
    }

    // MARK: - ClaudeResponse Decoding Tests

    func testClaudeResponseDecodesSuccessfully() throws {
        let json = """
        {
            "content": [
                {
                    "type": "text",
                    "text": "Welcome to Times Square!"
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        XCTAssertEqual(response.content.count, 1)
        XCTAssertEqual(response.content.first?.type, "text")
        XCTAssertEqual(response.content.first?.text, "Welcome to Times Square!")
    }

    func testClaudeResponseHandlesEmptyContent() throws {
        let json = """
        {
            "content": []
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        XCTAssertTrue(response.content.isEmpty)
    }

    func testClaudeResponseHandlesNullText() throws {
        let json = """
        {
            "content": [
                {
                    "type": "text",
                    "text": null
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        XCTAssertNil(response.content.first?.text)
    }

    // MARK: - Error Tests

    func testClaudeServiceErrorDescriptions() {
        XCTAssertEqual(
            ClaudeServiceError.invalidURL.errorDescription,
            "Invalid API URL"
        )
        XCTAssertEqual(
            ClaudeServiceError.invalidResponse.errorDescription,
            "Invalid response from server"
        )
        XCTAssertEqual(
            ClaudeServiceError.noContent.errorDescription,
            "No content in response"
        )
        XCTAssertEqual(
            ClaudeServiceError.apiError(statusCode: 401, message: "Unauthorized").errorDescription,
            "API error (401): Unauthorized"
        )
    }
}
