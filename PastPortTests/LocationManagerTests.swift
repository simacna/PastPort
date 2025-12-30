//
//  LocationManagerTests.swift
//  PastPortTests
//
//  Created by Sina S on 12/28/25.
//

import XCTest
import CoreLocation
import Combine
@testable import PastPort

final class LocationManagerTests: XCTestCase {

    var sut: LocationManager!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        sut = LocationManager()
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialStateIsCorrect() {
        XCTAssertNil(sut.currentLocation)
        XCTAssertEqual(sut.authorizationStatus, .notDetermined)
        XCTAssertNil(sut.locationError)
    }

    // MARK: - Significant Location Change Tests

    func testSignificantLocationChangePublisherExists() {
        // Verify the publisher exists and can be subscribed to
        let expectation = XCTestExpectation(description: "Publisher should exist")
        expectation.isInverted = true // We don't expect it to fire without location updates

        sut.significantLocationChange
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 0.1)
    }

    // MARK: - Mock Location Manager Tests

    func testMockLocationManagerTracksCallCounts() {
        let mockManager = MockLocationManager()

        XCTAssertEqual(mockManager.requestPermissionCallCount, 0)
        XCTAssertEqual(mockManager.startTrackingCallCount, 0)
        XCTAssertEqual(mockManager.stopTrackingCallCount, 0)

        mockManager.requestPermission()
        mockManager.startTracking()
        mockManager.stopTracking()

        XCTAssertEqual(mockManager.requestPermissionCallCount, 1)
        XCTAssertEqual(mockManager.startTrackingCallCount, 1)
        XCTAssertEqual(mockManager.stopTrackingCallCount, 1)
    }

    func testMockLocationManagerSimulatesLocationUpdate() {
        let mockManager = MockLocationManager()
        let testLocation = CLLocation(latitude: 40.7128, longitude: -74.0060)

        let expectation = XCTestExpectation(description: "Should receive location update")

        mockManager.significantLocationChange
            .sink { location in
                XCTAssertEqual(location.coordinate.latitude, 40.7128)
                XCTAssertEqual(location.coordinate.longitude, -74.0060)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        mockManager.simulateLocationUpdate(testLocation)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(mockManager.currentLocation)
    }

    func testMockLocationManagerSimulatesAuthorization() {
        let mockManager = MockLocationManager()

        XCTAssertEqual(mockManager.authorizationStatus, .notDetermined)

        mockManager.simulateAuthorization(.authorizedWhenInUse)
        XCTAssertEqual(mockManager.authorizationStatus, .authorizedWhenInUse)

        mockManager.simulateAuthorization(.denied)
        XCTAssertEqual(mockManager.authorizationStatus, .denied)
    }

    // MARK: - Distance Calculation Tests (Conceptual)

    func testDistanceCalculationBetweenTwoLocations() {
        let location1 = CLLocation(latitude: 40.7128, longitude: -74.0060) // NYC
        let location2 = CLLocation(latitude: 40.7580, longitude: -73.9855) // Times Square

        let distance = location1.distance(from: location2)

        // Distance should be approximately 5km
        XCTAssertGreaterThan(distance, 4000)
        XCTAssertLessThan(distance, 6000)
    }

    func testSignificantDistanceThreshold() {
        // Two locations less than 100m apart should NOT trigger significant change
        let location1 = CLLocation(latitude: 40.7128, longitude: -74.0060)
        let location2 = CLLocation(latitude: 40.7129, longitude: -74.0061)

        let distance = location1.distance(from: location2)
        let threshold: Double = 100

        XCTAssertLessThan(distance, threshold, "Locations should be within threshold")
    }

    func testLocationsExceedingThreshold() {
        // Two locations more than 100m apart SHOULD trigger significant change
        let location1 = CLLocation(latitude: 40.7128, longitude: -74.0060)
        let location2 = CLLocation(latitude: 40.7150, longitude: -74.0080)

        let distance = location1.distance(from: location2)
        let threshold: Double = 100

        XCTAssertGreaterThan(distance, threshold, "Locations should exceed threshold")
    }
}
