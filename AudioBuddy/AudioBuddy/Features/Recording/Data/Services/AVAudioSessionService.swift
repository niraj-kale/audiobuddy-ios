import AVFoundation

final class AVAudioSessionService: AudioSessionService {
    
    var permissionStatus: AVAudioSession.RecordPermission {
        AVAudioSession.sharedInstance().recordPermission
    }
    
    func configure() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
        try session.setActive(true)
    }
    
    func requestAuthorization() async throws {
        let granted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        if !granted {
            throw AudioSessionError.permissionDenied
        }
    }
}

enum AudioSessionError: Error {
    case permissionDenied
}
