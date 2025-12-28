import AVFoundation

final class AVAudioRecordingService: AudioRecordingService {
    private(set) var state: RecordingState = .idle
    
    private let engine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var converter: AVAudioConverter?
    private let sessionService: AudioSessionService
    
    init(sessionService: AudioSessionService) {
        self.sessionService = sessionService
    }
    
    func startRecording(to url: URL) async throws {
        guard state == .idle else { return }
        
        try await sessionService.configure()
        
        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        audioFile = try AVAudioFile(forWriting: url, settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 48000,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 128000
        ])
        
        let fileFormat = audioFile!.processingFormat
        converter = AVAudioConverter(from: inputFormat, to: fileFormat)
        
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self, let audioFile = self.audioFile, let converter = self.converter else { return }
            
            let convertedBuffer = AVAudioPCMBuffer(pcmFormat: fileFormat, frameCapacity: buffer.frameLength)!
            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            
            if status == .haveData, convertedBuffer.frameLength > 0 {
                try? audioFile.write(from: convertedBuffer)
            }
        }
        
        try engine.start()
        state = .recording
    }
    
    func pauseRecording() async throws {
        guard state == .recording else { return }
        engine.pause()
        state = .paused
    }
    
    func resumeRecording() async throws {
        guard state == .paused else { return }
        try engine.start()
        state = .recording
    }
    
    func stopRecording() async throws {
        guard state == .recording || state == .paused else { return }
        
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        audioFile = nil
        converter = nil
        state = .idle
    }
}
