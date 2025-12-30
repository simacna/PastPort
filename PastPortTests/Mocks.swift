//
//  Mocks.swift
//  PastPortTests
//
//  Created by Sina S on 12/28/25.
//

import Foundation
import CoreLocation
import Combine
@testable import PastPort

// MARK: - Mock Claude Service
class MockClaudeService: ClaudeServiceProtocol {
    var mockResponse: String = "This is a historic location with fascinating history."
    var shouldThrowError: Bool = false
    var errorToThrow: Error = ClaudeServiceError.noContent
    var getHistoricalContextCallCount = 0
    var lastRequestedLocation: CLLocation?

    func getHistoricalContext(for location: CLLocation) async throws -> String {
        getHistoricalContextCallCount += 1
        lastRequestedLocation = location

        if shouldThrowError {
            throw errorToThrow
        }
        return mockResponse
    }
}

// MARK: - Mock Location Manager
class MockLocationManager: ObservableObject, LocationManagerProtocol {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: Error?

    var requestPermissionCallCount = 0
    var startTrackingCallCount = 0
    var stopTrackingCallCount = 0

    let significantLocationChange = PassthroughSubject<CLLocation, Never>()

    func requestPermission() {
        requestPermissionCallCount += 1
    }

    func startTracking() {
        startTrackingCallCount += 1
    }

    func stopTracking() {
        stopTrackingCallCount += 1
    }

    // Test helper to simulate location update
    func simulateLocationUpdate(_ location: CLLocation) {
        currentLocation = location
        significantLocationChange.send(location)
    }

    // Test helper to simulate authorization change
    func simulateAuthorization(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
    }
}

// MARK: - Mock Speech Service
class MockSpeechService: ObservableObject, SpeechServiceProtocol {
    @Published var isSpeaking: Bool = false
    @Published var isPaused: Bool = false

    var speakCallCount = 0
    var lastSpokenText: String?
    var pauseCallCount = 0
    var resumeCallCount = 0
    var stopCallCount = 0

    func speak(_ text: String) {
        speakCallCount += 1
        lastSpokenText = text
        isSpeaking = true
        isPaused = false
    }

    func pause() {
        pauseCallCount += 1
        if isSpeaking {
            isPaused = true
        }
    }

    func resume() {
        resumeCallCount += 1
        if isPaused {
            isPaused = false
        }
    }

    func stop() {
        stopCallCount += 1
        isSpeaking = false
        isPaused = false
    }

    func togglePause() {
        if isPaused {
            resume()
        } else {
            pause()
        }
    }
}

// MARK: - Mock Geocoder
class MockGeocoder: GeocoderProtocol {
    var mockPlacemarks: [CLPlacemark] = []
    var shouldThrowError = false

    func reverseGeocodeLocation(_ location: CLLocation) async throws -> [CLPlacemark] {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1, userInfo: nil)
        }
        return mockPlacemarks
    }
}

// MARK: - Mock URL Protocol for Network Testing
class MockURLProtocol: URLProtocol {
    static var mockResponseData: Data?
    static var mockResponse: HTTPURLResponse?
    static var mockError: Error?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        if let response = MockURLProtocol.mockResponse {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        if let data = MockURLProtocol.mockResponseData {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func reset() {
        mockResponseData = nil
        mockResponse = nil
        mockError = nil
    }
}
