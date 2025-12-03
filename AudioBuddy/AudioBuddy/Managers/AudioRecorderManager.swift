//
//  AudioRecorderManager.swift
//  AudioBuddy
//
//  Manages audio recording functionality using AVFoundation.
//  All recordings are stored locally with no cloud connection.
//

import Foundation
import AVFoundation

@MainActor
class AudioRecorderManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var hasPermission = false
    @Published var errorMessage: String?
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var currentRecordingURL: URL?
    
    override init() {
        super.init()
        checkPermission()
    }
    
    func checkPermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            hasPermission = true
        case .denied:
            hasPermission = false
        case .undetermined:
            requestPermission()
        @unknown default:
            hasPermission = false
        }
    }
    
    func requestPermission() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                self?.hasPermission = granted
            }
        }
    }
    
    func startRecording() -> URL? {
        guard hasPermission else {
            errorMessage = "Microphone permission not granted"
            return nil
        }
        
        // Set up audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            errorMessage = "Failed to set up audio session: \(error.localizedDescription)"
            return nil
        }
        
        // Create unique filename with timestamp
        let timestamp = Date().timeIntervalSince1970
        let filename = "recording_\(Int(timestamp)).m4a"
        let fileURL = Recording.recordingsDirectory.appendingPathComponent(filename)
        
        // Audio recording settings - high quality, local-only format
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            recordingDuration = 0
            currentRecordingURL = fileURL
            
            // Start timer to track duration
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.recordingDuration += 1
                }
            }
            
            return fileURL
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            return nil
        }
    }
    
    func stopRecording() -> (url: URL, duration: TimeInterval)? {
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        guard let recorder = audioRecorder, isRecording else {
            return nil
        }
        
        let duration = recorder.currentTime
        recorder.stop()
        
        isRecording = false
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
        
        guard let url = currentRecordingURL else {
            return nil
        }
        
        let result = (url: url, duration: duration)
        
        audioRecorder = nil
        currentRecordingURL = nil
        recordingDuration = 0
        
        return result
    }
    
    func cancelRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        audioRecorder?.stop()
        
        // Delete the file if it exists
        if let url = currentRecordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        isRecording = false
        audioRecorder = nil
        currentRecordingURL = nil
        recordingDuration = 0
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension AudioRecorderManager: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                errorMessage = "Recording did not complete successfully"
            }
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            errorMessage = error?.localizedDescription ?? "Encoding error occurred"
        }
    }
}
