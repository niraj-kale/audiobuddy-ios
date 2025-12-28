import Foundation

protocol StopRecordingUseCase {
    func execute() async throws
}

final class StopRecordingUseCaseImpl: StopRecordingUseCase {
    private let recordingService: AudioRecordingService
    
    init(recordingService: AudioRecordingService) {
        self.recordingService = recordingService
    }
    
    func execute() async throws {
        try await recordingService.stopRecording()
    }
}
