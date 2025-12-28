import Foundation
import GRDB

struct RecordingDTO: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "recording"
    
    var id: String
    var title: String
    var date: Date
    var duration: Double
    var audioPath: String
}

