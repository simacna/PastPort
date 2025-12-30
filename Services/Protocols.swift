//
//  Protocols.swift
//  PastPort
//
//  Created by Sina S on 12/28/25.
//

import Foundation
import CoreLocation

// MARK: - Claude Service Protocol
protocol ClaudeServiceProtocol {
    func getHistoricalContext(for location: CLLocation) async throws -> String
}

extension ClaudeService: ClaudeServiceProtocol {}

// MARK: - Location Manager Protocol
protocol LocationManagerProtocol: ObservableObject {
    var currentLocation: CLLocation? { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    var locationError: Error? { get }

    func requestPermission()
    func startTracking()
    func stopTracking()
}

extension LocationManager: LocationManagerProtocol {}

// MARK: - Speech Service Protocol
protocol SpeechServiceProtocol: ObservableObject {
    var isSpeaking: Bool { get }
    var isPaused: Bool { get }

    func speak(_ text: String)
    func pause()
    func resume()
    func stop()
    func togglePause()
}

extension SpeechService: SpeechServiceProtocol {}

// MARK: - Geocoder Protocol (for mocking CLGeocoder)
protocol GeocoderProtocol {
    func reverseGeocodeLocation(_ location: CLLocation) async throws -> [CLPlacemark]
}

extension CLGeocoder: GeocoderProtocol {}
