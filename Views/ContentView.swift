//
//  ContentView.swift
//  PastPort
//
//  Created by Sina S on 12/28/25.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = TourGuideViewModel()
    @State private var showingAPIKeyAlert = false
    @State private var apiKeyInput = ""

    var body: some View {
        ZStack {
            // Map
            Map(coordinateRegion: $viewModel.mapRegion, showsUserLocation: true)
                .ignoresSafeArea()

            // Bottom control panel
            VStack {
                Spacer()

                // Narration card
                if !viewModel.currentNarration.isEmpty || viewModel.isLoading {
                    narrationCard
                }

                // Control buttons
                controlBar
            }

            // API Key missing overlay
            if !viewModel.hasAPIKey {
                apiKeyOverlay
            }
        }
        .onAppear {
            if viewModel.hasAPIKey {
                viewModel.start()
            } else {
                showingAPIKeyAlert = true
            }
        }
        .alert("Enter Claude API Key", isPresented: $showingAPIKeyAlert) {
            TextField("sk-ant-...", text: $apiKeyInput)
            Button("Save") {
                viewModel.setAPIKey(apiKeyInput)
                viewModel.start()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your API key is stored locally on your device.")
        }
    }

    private var narrationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Discovering history...")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView {
                    Text(viewModel.currentNarration)
                        .foregroundColor(.white)
                        .font(.body)
                }
                .frame(maxHeight: 150)
                .padding()
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
        }
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var controlBar: some View {
        HStack(spacing: 20) {
            // Refresh button
            Button(action: {
                viewModel.refreshCurrentLocation()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            .disabled(viewModel.isLoading)

            // Play/Pause button
            Button(action: {
                viewModel.toggleSpeech()
            }) {
                Image(systemName: viewModel.speechService.isPaused ? "play.fill" : "pause.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(viewModel.speechService.isSpeaking ? Color.green : Color.gray)
                    .clipShape(Circle())
            }
            .disabled(!viewModel.speechService.isSpeaking && viewModel.currentNarration.isEmpty)

            // Stop button
            Button(action: {
                viewModel.stopSpeech()
            }) {
                Image(systemName: "stop.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.red)
                    .clipShape(Circle())
            }
            .disabled(!viewModel.speechService.isSpeaking)
        }
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(20)
        .padding(.bottom, 30)
    }

    private var apiKeyOverlay: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("API Key Required")
                .font(.title2)
                .fontWeight(.bold)

            Text("To use History Guide, you need a Claude API key from Anthropic.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button("Enter API Key") {
                showingAPIKeyAlert = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(30)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
}

#Preview {
    ContentView()
}
