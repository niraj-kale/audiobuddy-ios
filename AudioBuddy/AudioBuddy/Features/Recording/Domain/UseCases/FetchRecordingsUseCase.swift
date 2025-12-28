import Foundation

enum RecordingSortOrder {
    case dateDescending
    case dateAscending
    case durationDescending
    case durationAscending
    case titleAscending
    case titleDescending
}

protocol FetchRecordingsUseCase {
    func execute(sortOrder: RecordingSortOrder) async throws -> [Recording]
}

final class FetchRecordingsUseCaseImpl: FetchRecordingsUseCase {
    private let repository: RecordingRepository
    
    init(repository: RecordingRepository) {
        self.repository = repository
    }
    
    func execute(sortOrder: RecordingSortOrder = .dateDescending) async throws -> [Recording] {
        let recordings = try await repository.fetchAll()
        return sort(recordings, by: sortOrder)
    }
    
    private func sort(_ recordings: [Recording], by order: RecordingSortOrder) -> [Recording] {
        switch order {
        case .dateDescending:
            return recordings.sorted { $0.date > $1.date }
        case .dateAscending:
            return recordings.sorted { $0.date < $1.date }
        case .durationDescending:
            return recordings.sorted { $0.duration > $1.duration }
        case .durationAscending:
            return recordings.sorted { $0.duration < $1.duration }
        case .titleAscending:
            return recordings.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .titleDescending:
            return recordings.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        }
    }
}

