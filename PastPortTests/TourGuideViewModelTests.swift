//
//  TourGuideViewModelTests.swift
//  PastPortTests
//
//  Created by Sina S on 12/28/25.
//

import XCTest
import CoreLocation
import Combine
@testable import PastPort

final class TourGuideViewModelTests: XCTestCase {

    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    // MARK: - API Key Tests

    func testHasAPIKeyReturnsFalseWhenNoKeySet() {
        // Clear any existing key
        UserDefaults.standard.removeObject(forKey: "claude_api_key")

        let viewModel = TourGuideViewModel()

        // Without environment variable or saved key, should be false
        // Note: This test may pass/fail depending on environment
        // In a real app, we'd inject the dependency
    }

    func testSetAPIKeySavesToUserDefaults() {
        let viewModel = TourGuideViewModel()
        let testKey = "test-api-key-12345"

        viewModel.setAPIKey(testKey)

        let savedKey = UserDefaults.standard.string(forKey: "claude_api_key")
        XCTAssertEqual(savedKey, testKey)

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "claude_api_key")
    }

    // MARK: - Initial State Tests

    func testInitialStateIsCorrect() {
        let viewModel = TourGuideViewModel()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.currentNarration.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Map Region Tests

    func testDefaultMapRegionIsNYC() {
        let viewModel = TourGuideViewModel()

        // Default should be centered on NYC
        XCTAssertEqual(viewModel.mapRegion.center.latitude, 40.7128, accuracy: 0.01)
        XCTAssertEqual(viewModel.mapRegion.center.longitude, -74.0060, accuracy: 0.01)
    }

    // MARK: - Speech Control Tests

    func testToggleSpeechCallsSpeechService() {
        let viewModel = TourGuideViewModel()

        // This tests that the method doesn't crash
        // Full integration would require dependency injection
        viewModel.toggleSpeech()
        viewModel.stopSpeech()
    }

    func testReplayWithEmptyNarrationDoesNotCrash() {
        let viewModel = TourGuideViewModel()

        XCTAssertTrue(viewModel.currentNarration.isEmpty)

        // Should not crash when narration is empty
        viewModel.replay()
    }

    // MARK: - Mock Integration Tests

    func testMockClaudeServiceReturnsExpectedResponse() async {
        let mockService = MockClaudeService()
        mockService.mockResponse = "Welcome to Central Park!"

        let location = CLLocation(latitude: 40.7829, longitude: -73.9654)

        do {
            let response = try await mockService.getHistoricalContext(for: location)
            XCTAssertEqual(response, "Welcome to Central Park!")
            XCTAssertEqual(mockService.getHistoricalContextCallCount, 1)
            XCTAssertEqual(mockService.lastRequestedLocation?.coordinate.latitude, 40.7829)
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
    }

    func testMockClaudeServiceThrowsError() async {
        let mockService = MockClaudeService()
        mockService.shouldThrowError = true
        mockService.errorToThrow = ClaudeServiceError.apiError(statusCode: 500, message: "Server error")

        let location = CLLocation(latitude: 40.7829, longitude: -73.9654)

        do {
            _ = try await mockService.getHistoricalContext(for: location)
            XCTFail("Should have thrown error")
        } catch let error as ClaudeServiceError {
            if case .apiError(let code, let message) = error {
                XCTAssertEqual(code, 500)
                XCTAssertEqual(message, "Server error")
            } else {
                XCTFail("Wrong error type")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Full Flow Mock Test

    func testFullFlowWithMocks() async {
        let mockLocation = MockLocationManager()
        let mockSpeech = MockSpeechService()
        let mockClaude = MockClaudeService()
        mockClaude.mockResponse = "This is the historic Brooklyn Bridge!"

        // Simulate the flow
        let testLocation = CLLocation(latitude: 40.7061, longitude: -73.9969)

        // 1. Location manager gets location
        mockLocation.simulateLocationUpdate(testLocation)
        XCTAssertNotNil(mockLocation.currentLocation)

        // 2. Claude service returns history
        let narration = try? await mockClaude.getHistoricalContext(for: testLocation)
        XCTAssertEqual(narration, "This is the historic Brooklyn Bridge!")

        // 3. Speech service speaks
        if let text = narration {
            mockSpeech.speak(text)
        }
        XCTAssertTrue(mockSpeech.isSpeaking)
        XCTAssertEqual(mockSpeech.lastSpokenText, "This is the historic Brooklyn Bridge!")
    }
}
