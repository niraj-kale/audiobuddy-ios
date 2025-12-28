import Foundation
import os.log

/// Lightweight logger for AudioBuddy
/// - Only logs in DEBUG builds
/// - Uses Apple's unified logging system (os.log)
enum Logger {
    
    private static let subsystem = Bundle.main.bundleIdentifier ?? "AudioBuddy"
    
    // MARK: - Log Categories
    private static let general = OSLog(subsystem: subsystem, category: "General")
    private static let database = OSLog(subsystem: subsystem, category: "Database")
    private static let audio = OSLog(subsystem: subsystem, category: "Audio")
    private static let recording = OSLog(subsystem: subsystem, category: "Recording")
    
    enum Category {
        case general
        case database
        case audio
        case recording
        
        var osLog: OSLog {
            switch self {
            case .general: return Logger.general
            case .database: return Logger.database
            case .audio: return Logger.audio
            case .recording: return Logger.recording
            }
        }
    }
    
    // MARK: - Log Methods
    
    /// Debug level - verbose information for development
    static func debug(_ message: String, category: Category = .general, file: String = #file, function: String = #function) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        os_log(.debug, log: category.osLog, "%{public}@ [%{public}@] %{public}@", filename, function, message)
        #endif
    }
    
    /// Info level - general information
    static func info(_ message: String, category: Category = .general) {
        #if DEBUG
        os_log(.info, log: category.osLog, "%{public}@", message)
        #endif
    }
    
    /// Warning level - potential issues
    static func warning(_ message: String, category: Category = .general) {
        #if DEBUG
        os_log(.default, log: category.osLog, "⚠️ %{public}@", message)
        #endif
    }
    
    /// Error level - failures that need attention
    static func error(_ message: String, error: Error? = nil, category: Category = .general) {
        #if DEBUG
        if let error = error {
            os_log(.error, log: category.osLog, "❌ %{public}@: %{public}@", message, error.localizedDescription)
        } else {
            os_log(.error, log: category.osLog, "❌ %{public}@", message)
        }
        #endif
    }
}

