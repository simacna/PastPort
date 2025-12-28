//
//  LocationManager.swift
//  PastPort
//
//  Created by Sina S on 12/28/25.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: Error?

    // Threshold for "significant" location change (in meters)
    private let significantDistanceThreshold: Double = 100
    private var lastReportedLocation: CLLocation?

    // Publisher that emits when location changes significantly
    let significantLocationChange = PassthroughSubject<CLLocation, Never>()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50 // Update every 50 meters
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        locationManager.startUpdatingLocation()
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
    }

    private func handleNewLocation(_ location: CLLocation) {
        currentLocation = location

        // Check if this is a significant change from last reported location
        if let lastLocation = lastReportedLocation {
            let distance = location.distance(from: lastLocation)
            if distance >= significantDistanceThreshold {
                lastReportedLocation = location
                significantLocationChange.send(location)
            }
        } else {
            // First location - always report
            lastReportedLocation = location
            significantLocationChange.send(location)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        handleNewLocation(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startTracking()
        case .denied, .restricted:
            stopTracking()
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}
