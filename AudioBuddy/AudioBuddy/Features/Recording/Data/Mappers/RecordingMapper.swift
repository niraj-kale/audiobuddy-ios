import Foundation

enum RecordingMapper {
    static func toEntity(_ dto: RecordingDTO) -> Recording {
        Recording(
            id: UUID(uuidString: dto.id) ?? UUID(),
            title: dto.title,
            date: dto.date,
            duration: dto.duration,
            audioURL: URL(fileURLWithPath: dto.audioPath)
        )
    }
    
    static func toDTO(_ entity: Recording) -> RecordingDTO {
        RecordingDTO(
            id: entity.id.uuidString,
            title: entity.title,
            date: entity.date,
            duration: entity.duration,
            audioPath: entity.audioURL.path
        )
    }
}

