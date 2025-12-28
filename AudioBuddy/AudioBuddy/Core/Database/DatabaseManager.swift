import Foundation
import GRDB

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var dbQueue: DatabaseQueue?
    
    var database: DatabaseQueue {
        guard let dbQueue else {
            fatalError("DatabaseManager not initialized. Call setup() first.")
        }
        return dbQueue
    }
    
    private init() {}
    
    // MARK: - Setup
    
    func setup() throws {
        let databaseURL = try getDatabaseURL()
        let config = Configuration()
        dbQueue = try DatabaseQueue(path: databaseURL.path, configuration: config)
        try runMigrations()
        Logger.info("Database initialized", category: .database)
    }
    
    // MARK: - Migrations
    
    private func runMigrations() throws {
        guard let dbQueue else { return }
        
        var migrator = DatabaseMigrator()
        
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        
        // Migration v1: Recording table
        migrator.registerMigration("v1_recording") { db in
            try db.create(table: "recording") { t in
                t.column("id", .text).primaryKey()
                t.column("title", .text).notNull()
                t.column("date", .datetime).notNull()
                t.column("duration", .double).notNull()
                t.column("audioPath", .text).notNull()
            }
        }
        
        try migrator.migrate(dbQueue)
    }
    
    // MARK: - Helpers
    
    private func getDatabaseURL() throws -> URL {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let databaseDirectory = appSupportURL.appendingPathComponent("Database", isDirectory: true)
        
        if !fileManager.fileExists(atPath: databaseDirectory.path) {
            try fileManager.createDirectory(
                at: databaseDirectory,
                withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.complete]
            )
        }
        
        return databaseDirectory.appendingPathComponent("audiobuddy.sqlite")
    }
}

