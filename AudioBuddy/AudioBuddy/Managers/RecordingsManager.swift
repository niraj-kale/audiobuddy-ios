//
//  RecordingsManager.swift
//  AudioBuddy
//
//  Manages saved recordings stored locally on device.
//  No cloud or network connectivity - all data stays private.
//

import Foundation

@MainActor
class RecordingsManager: ObservableObject {
    @Published var recordings: [Recording] = []
    
    private let metadataFileName = "recordings_metadata.json"
    
    private var metadataURL: URL {
        Recording.recordingsDirectory.appendingPathComponent(metadataFileName)
    }
    
    init() {
        loadRecordings()
    }
    
    func loadRecordings() {
        guard FileManager.default.fileExists(atPath: metadataURL.path) else {
            recordings = []
            return
        }
        
        do {
            let data = try Data(contentsOf: metadataURL)
            let decoder = JSONDecoder()
            recordings = try decoder.decode([Recording].self, from: data)
            
            // Filter out recordings whose files no longer exist
            recordings = recordings.filter { recording in
                FileManager.default.fileExists(atPath: recording.fileURL.path)
            }
            
            // Sort by date, newest first
            recordings.sort { $0.createdAt > $1.createdAt }
        } catch {
            recordings = []
        }
    }
    
    func saveRecording(url: URL, duration: TimeInterval) {
        let filename = url.lastPathComponent
        let recording = Recording(filename: filename, duration: duration)
        
        recordings.insert(recording, at: 0)
        saveMetadata()
    }
    
    func deleteRecording(_ recording: Recording) {
        // Delete the audio file
        try? FileManager.default.removeItem(at: recording.fileURL)
        
        // Remove from list
        recordings.removeAll { $0.id == recording.id }
        saveMetadata()
    }
    
    func deleteRecording(at offsets: IndexSet) {
        for index in offsets {
            let recording = recordings[index]
            try? FileManager.default.removeItem(at: recording.fileURL)
        }
        recordings.remove(atOffsets: offsets)
        saveMetadata()
    }
    
    private func saveMetadata() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(recordings)
            try data.write(to: metadataURL, options: .atomic)
        } catch {
            // Failed to save metadata - recordings will be lost on next app launch
            // but audio files will still exist
        }
    }
    
    func getTotalDuration() -> TimeInterval {
        return recordings.reduce(0) { $0 + $1.duration }
    }
    
    var formattedTotalDuration: String {
        let total = getTotalDuration()
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        let seconds = Int(total) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
