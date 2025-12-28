import Foundation

final class InMemoryRecordingRepository: RecordingRepository {
    private var recordings: [Recording] = []
    
    func fetchAll() async throws -> [Recording] {
        return recordings
    }
    
    func save(_ recording: Recording) async throws {
        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings[index] = recording
        } else {
            recordings.append(recording)
        }
    }
    
    func update(_ recording: Recording) async throws {
        guard let index = recordings.firstIndex(where: { $0.id == recording.id }) else { return }
        recordings[index] = recording
    }
    
    func delete(_ recording: Recording) async throws {
        recordings.removeAll { $0.id == recording.id }
    }
    
    func fetch(by id: UUID) async throws -> Recording? {
        return recordings.first { $0.id == id }
    }
}

