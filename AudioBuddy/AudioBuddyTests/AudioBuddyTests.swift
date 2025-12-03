//
//  AudioBuddyTests.swift
//  AudioBuddyTests
//
//  Unit tests for Audio Buddy app.
//

import XCTest
@testable import AudioBuddy

final class AudioBuddyTests: XCTestCase {
    
    // MARK: - Recording Model Tests
    
    func testRecordingInitialization() {
        let recording = Recording(filename: "test.m4a", duration: 120)
        
        XCTAssertEqual(recording.filename, "test.m4a")
        XCTAssertEqual(recording.duration, 120)
        XCTAssertNotNil(recording.id)
    }
    
    func testRecordingFormattedDuration() {
        let recording = Recording(filename: "test.m4a", duration: 125)
        XCTAssertEqual(recording.formattedDuration, "02:05")
        
        let shortRecording = Recording(filename: "short.m4a", duration: 5)
        XCTAssertEqual(shortRecording.formattedDuration, "00:05")
        
        let longRecording = Recording(filename: "long.m4a", duration: 3661)
        XCTAssertEqual(longRecording.formattedDuration, "61:01")
    }
    
    func testRecordingFormattedDate() {
        let recording = Recording(filename: "test.m4a", createdAt: Date(), duration: 60)
        XCTAssertFalse(recording.formattedDate.isEmpty)
    }
    
    func testRecordingFileURL() {
        let recording = Recording(filename: "test_file.m4a", duration: 60)
        XCTAssertTrue(recording.fileURL.path.contains("Recordings"))
        XCTAssertTrue(recording.fileURL.path.contains("test_file.m4a"))
    }
    
    func testRecordingsDirectoryCreation() {
        let directory = Recording.recordingsDirectory
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))
    }
    
    // MARK: - Recording Codable Tests
    
    func testRecordingEncodeDecode() throws {
        let original = Recording(filename: "test.m4a", duration: 180)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Recording.self, from: data)
        
        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.filename, decoded.filename)
        XCTAssertEqual(original.duration, decoded.duration)
    }
}
