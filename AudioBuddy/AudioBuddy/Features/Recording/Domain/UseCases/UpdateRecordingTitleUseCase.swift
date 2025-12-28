import Foundation

protocol UpdateRecordingTitleUseCase {
    func execute(recording: Recording, newTitle: String) async throws
}

final class UpdateRecordingTitleUseCaseImpl: UpdateRecordingTitleUseCase {
    private let repository: RecordingRepository
    
    init(repository: RecordingRepository) {
        self.repository = repository
    }
    
    func execute(recording: Recording, newTitle: String) async throws {
        var updatedRecording = recording
        updatedRecording.title = newTitle
        try await repository.update(updatedRecording)
    }
}

