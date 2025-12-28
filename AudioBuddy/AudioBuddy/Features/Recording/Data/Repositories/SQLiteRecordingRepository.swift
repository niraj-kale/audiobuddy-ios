import Foundation
import GRDB

final class SQLiteRecordingRepository: RecordingRepository {
    private let database: DatabaseQueue
    
    init(database: DatabaseQueue) {
        self.database = database
    }
    
    func fetchAll() async throws -> [Recording] {
        try await database.read { db in
            let dtos = try RecordingDTO.fetchAll(db)
            return dtos.map(RecordingMapper.toEntity)
        }
    }
    
    func save(_ recording: Recording) async throws {
        let dto = RecordingMapper.toDTO(recording)
        try await database.write { db in
            try dto.save(db)
        }
    }
    
    func update(_ recording: Recording) async throws {
        let dto = RecordingMapper.toDTO(recording)
        try await database.write { db in
            try dto.update(db)
        }
    }
    
    func delete(_ recording: Recording) async throws {
        let dto = RecordingMapper.toDTO(recording)
        try await database.write { db in
            try dto.delete(db)
        }
    }
    
    func fetch(by id: UUID) async throws -> Recording? {
        try await database.read { db in
            guard let dto = try RecordingDTO.fetchOne(db, key: id.uuidString) else {
                return nil
            }
            return RecordingMapper.toEntity(dto)
        }
    }
}

