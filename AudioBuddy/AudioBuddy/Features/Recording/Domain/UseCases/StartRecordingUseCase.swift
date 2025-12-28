//
//  StartRecordingUseCase.swift
//  AudioBuddy
//
//  Created by Niraj Kale on 15/12/25.
//

import Foundation

protocol StartRecordingUseCase {
    func execute(to url: URL) async throws
}

final class StartRecordingUseCaseImpl: StartRecordingUseCase {
    private let recordingService: AudioRecordingService
    private let sessionService: AudioSessionService
    
    init(recordingService: AudioRecordingService, sessionService: AudioSessionService) {
        self.recordingService = recordingService
        self.sessionService = sessionService
    }
    
    func execute(to url: URL) async throws {
        try await sessionService.configure()
        try await recordingService.startRecording(to: url)
    }
}
