//
//  TourGuideViewModel.swift
//  PastPort
//
//  Created by Sina S on 12/28/25.
//

import Foundation
import CoreLocation
import Combine
import MapKit

@MainActor
class TourGuideViewModel: ObservableObject {
    // Services
    let locationManager = LocationManager()
    let speechService = SpeechService()
    private var claudeService: ClaudeService?

    // State
    @Published var isLoading: Bool = false
    @Published var currentNarration: String = ""
    @Published var errorMessage: String?
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), // NYC default
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    private var cancellables = Set<AnyCancellable>()
    private var hasSpokenInitial = false

    init() {
        setupClaudeService()
        setupLocationSubscription()
    }

    private func setupClaudeService() {
        // TODO: Replace with your actual API key or load from secure storage
        // For MVP, we'll use a placeholder - user needs to add their key
        if let apiKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] {
            claudeService = ClaudeService(apiKey: apiKey)
        } else {
            // Fallback: Try to load from UserDefaults or show error
            if let savedKey = UserDefaults.standard.string(forKey: "claude_api_key"), !savedKey.isEmpty {
                claudeService = ClaudeService(apiKey: savedKey)
            }
        }
    }

    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "claude_api_key")
        claudeService = ClaudeService(apiKey: key)
    }

    var hasAPIKey: Bool {
        claudeService != nil
    }

    private func setupLocationSubscription() {
        locationManager.significantLocationChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                Task {
                    await self?.handleLocationUpdate(location)
                }
            }
            .store(in: &cancellables)

        // Update map region when location changes
        locationManager.$currentLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.mapRegion = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
            .store(in: &cancellables)
    }

    func start() {
        locationManager.requestPermission()
    }

    private func handleLocationUpdate(_ location: CLLocation) async {
        guard let claudeService = claudeService else {
            errorMessage = "Please set your Claude API key"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let narration = try await claudeService.getHistoricalContext(for: location)
            currentNarration = narration
            speechService.speak(narration)
        } catch {
            errorMessage = error.localizedDescription
            currentNarration = ""
        }

        isLoading = false
    }

    func toggleSpeech() {
        speechService.togglePause()
    }

    func stopSpeech() {
        speechService.stop()
    }

    func replay() {
        if !currentNarration.isEmpty {
            speechService.speak(currentNarration)
        }
    }

    func refreshCurrentLocation() {
        if let location = locationManager.currentLocation {
            Task {
                await handleLocationUpdate(location)
            }
        }
    }
}
