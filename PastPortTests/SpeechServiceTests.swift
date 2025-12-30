//
//  SpeechServiceTests.swift
//  PastPortTests
//
//  Created by Sina S on 12/28/25.
//

import XCTest
@testable import PastPort

final class SpeechServiceTests: XCTestCase {

    var sut: SpeechService!

    override func setUp() {
        super.setUp()
        sut = SpeechService()
    }

    override func tearDown() {
        sut.stop()
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialStateIsNotSpeaking() {
        XCTAssertFalse(sut.isSpeaking)
        XCTAssertFalse(sut.isPaused)
    }

    // MARK: - Mock Speech Service Tests

    func testMockSpeechServiceTracksSpokenText() {
        let mockService = MockSpeechService()

        mockService.speak("Hello, world!")

        XCTAssertEqual(mockService.speakCallCount, 1)
        XCTAssertEqual(mockService.lastSpokenText, "Hello, world!")
        XCTAssertTrue(mockService.isSpeaking)
    }

    func testMockSpeechServicePauseResumeCycle() {
        let mockService = MockSpeechService()

        // Start speaking
        mockService.speak("Test speech")
        XCTAssertTrue(mockService.isSpeaking)
        XCTAssertFalse(mockService.isPaused)

        // Pause
        mockService.pause()
        XCTAssertTrue(mockService.isSpeaking)
        XCTAssertTrue(mockService.isPaused)
        XCTAssertEqual(mockService.pauseCallCount, 1)

        // Resume
        mockService.resume()
        XCTAssertTrue(mockService.isSpeaking)
        XCTAssertFalse(mockService.isPaused)
        XCTAssertEqual(mockService.resumeCallCount, 1)
    }

    func testMockSpeechServiceStop() {
        let mockService = MockSpeechService()

        mockService.speak("Test speech")
        XCTAssertTrue(mockService.isSpeaking)

        mockService.stop()
        XCTAssertFalse(mockService.isSpeaking)
        XCTAssertFalse(mockService.isPaused)
        XCTAssertEqual(mockService.stopCallCount, 1)
    }

    func testMockSpeechServiceTogglePause() {
        let mockService = MockSpeechService()

        mockService.speak("Test speech")

        // Toggle to pause
        mockService.togglePause()
        XCTAssertTrue(mockService.isPaused)

        // Toggle to resume
        mockService.togglePause()
        XCTAssertFalse(mockService.isPaused)
    }

    func testMockSpeechServicePauseWhenNotSpeakingDoesNothing() {
        let mockService = MockSpeechService()

        XCTAssertFalse(mockService.isSpeaking)

        mockService.pause()
        XCTAssertFalse(mockService.isPaused) // Should remain false since not speaking
    }

    func testMockSpeechServiceMultipleSpeakCallsOverwrite() {
        let mockService = MockSpeechService()

        mockService.speak("First message")
        mockService.speak("Second message")

        XCTAssertEqual(mockService.speakCallCount, 2)
        XCTAssertEqual(mockService.lastSpokenText, "Second message")
    }
}
