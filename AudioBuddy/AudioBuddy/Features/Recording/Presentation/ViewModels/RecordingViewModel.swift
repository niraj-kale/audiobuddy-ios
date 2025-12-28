import Foundation
import Combine
import AVFoundation

@MainActor
final class RecordingViewModel: ObservableObject {
    @Published var state: RecordingState = .idle
    @Published var duration: TimeInterval = 0
    @Published var permissionDenied: Bool = false
    @Published var errorMessage: String?
    
    private let startRecordingUseCase: StartRecordingUseCase
    private let stopRecordingUseCase: StopRecordingUseCase
    private let audioSessionService: AudioSessionService
    private let recordingRepository: RecordingRepository
    
    private var timerCancellable: AnyCancellable?
    private var currentRecordingURL: URL?
    
    var onRecordingSaved: (() -> Void)?
    
    var isRecording: Bool {
        state == .recording
    }
    
    var isPaused: Bool {
        state == .paused
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    init(
        startRecordingUseCase: StartRecordingUseCase,
        stopRecordingUseCase: StopRecordingUseCase,
        audioSessionService: AudioSessionService,
        recordingRepository: RecordingRepository
    ) {
        self.startRecordingUseCase = startRecordingUseCase
        self.stopRecordingUseCase = stopRecordingUseCase
        self.audioSessionService = audioSessionService
        self.recordingRepository = recordingRepository
        
        checkPermissionStatus()
    }
    
    // MARK: - Permission
    
    func checkPermissionStatus() {
        permissionDenied = audioSessionService.permissionStatus == .denied
    }
    
    func requestPermission() async {
        do {
            try await audioSessionService.requestAuthorization()
            permissionDenied = false
        } catch {
            permissionDenied = true
        }
    }
    
    // MARK: - Recording Actions
    
    func startRecording() {
        guard audioSessionService.permissionStatus != .denied else {
            permissionDenied = true
            return
        }
        
        Task {
            do {
                let url = generateRecordingURL()
                currentRecordingURL = url
                try await startRecordingUseCase.execute(to: url)
                state = .recording
                duration = 0
                startTimer()
                errorMessage = nil
            } catch {
                errorMessage = "Failed to start recording: \(error.localizedDescription)"
                state = .idle
            }
        }
    }
    
    func pauseRecording() {
        guard state == .recording else { return }
        state = .paused
        stopTimer()
    }
    
    func resumeRecording() {
        guard state == .paused else { return }
        state = .recording
        startTimer()
    }
    
    func stopRecording() {
        Task {
            do {
                let finalDuration = duration
                stopTimer()
                try await stopRecordingUseCase.execute()
                
                if let url = currentRecordingURL {
                    let recording = Recording(
                        id: UUID(),
                        title: generateTitle(),
                        date: Date(),
                        duration: finalDuration,
                        audioURL: url
                    )
                    try await recordingRepository.save(recording)
                    onRecordingSaved?()
                }
                
                state = .idle
                duration = 0
                currentRecordingURL = nil
                errorMessage = nil
            } catch {
                errorMessage = "Failed to save recording: \(error.localizedDescription)"
            }
        }
    }
    
    func discardRecording() {
        Task {
            stopTimer()
            try? await stopRecordingUseCase.execute()
            
            if let url = currentRecordingURL {
                try? FileManager.default.removeItem(at: url)
            }
            
            state = .idle
            duration = 0
            currentRecordingURL = nil
        }
    }
    
    // MARK: - Helpers
    
    private func generateRecordingURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recording_\(UUID().uuidString).m4a"
        return documentsPath.appendingPathComponent(fileName)
    }
    
    private func generateTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: Date())
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.duration += 1
            }
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}
