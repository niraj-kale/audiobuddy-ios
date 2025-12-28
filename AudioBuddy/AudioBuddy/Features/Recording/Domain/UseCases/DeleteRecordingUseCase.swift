import Foundation

protocol DeleteRecordingUseCase {
    func execute(_ recording: Recording) async throws
}

final class DeleteRecordingUseCaseImpl: DeleteRecordingUseCase {
    private let repository: RecordingRepository
    
    init(repository: RecordingRepository) {
        self.repository = repository
    }
    
    func execute(_ recording: Recording) async throws {
        // Delete audio file
        try? FileManager.default.removeItem(at: recording.audioURL)
        // Delete from database
        try await repository.delete(recording)
    }
}

