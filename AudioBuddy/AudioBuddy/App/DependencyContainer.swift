import Foundation
import Combine

final class DependencyContainer: ObservableObject {
    
    // MARK: - Services
    
    lazy var audioSessionService: AudioSessionService = {
        AVAudioSessionService()
    }()
    
    lazy var audioRecordingService: AudioRecordingService = {
        AVAudioRecordingService(sessionService: audioSessionService)
    }()
    
    // MARK: - Repositories
    
    lazy var recordingRepository: RecordingRepository = {
        SQLiteRecordingRepository(database: DatabaseManager.shared.database)
    }()
    
    // MARK: - Use Cases
    
    lazy var startRecordingUseCase: StartRecordingUseCase = {
        StartRecordingUseCaseImpl(
            recordingService: audioRecordingService,
            sessionService: audioSessionService
        )
    }()
    
    lazy var stopRecordingUseCase: StopRecordingUseCase = {
        StopRecordingUseCaseImpl(recordingService: audioRecordingService)
    }()
    
    lazy var fetchRecordingsUseCase: FetchRecordingsUseCase = {
        FetchRecordingsUseCaseImpl(repository: recordingRepository)
    }()
    
    lazy var deleteRecordingUseCase: DeleteRecordingUseCase = {
        DeleteRecordingUseCaseImpl(repository: recordingRepository)
    }()
    
    lazy var updateRecordingTitleUseCase: UpdateRecordingTitleUseCase = {
        UpdateRecordingTitleUseCaseImpl(repository: recordingRepository)
    }()
}
