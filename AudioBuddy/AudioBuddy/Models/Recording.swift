//
//  Recording.swift
//  AudioBuddy
//
//  Model representing a saved audio recording.
//

import Foundation

struct Recording: Identifiable, Codable {
    let id: UUID
    let filename: String
    let createdAt: Date
    var duration: TimeInterval
    
    init(id: UUID = UUID(), filename: String, createdAt: Date = Date(), duration: TimeInterval = 0) {
        self.id = id
        self.filename = filename
        self.createdAt = createdAt
        self.duration = duration
    }
    
    var fileURL: URL {
        Recording.recordingsDirectory.appendingPathComponent(filename)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    static var recordingsDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsPath = documentsPath.appendingPathComponent("Recordings")
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: recordingsPath.path) {
            try? FileManager.default.createDirectory(at: recordingsPath, withIntermediateDirectories: true)
        }
        
        return recordingsPath
    }
}
