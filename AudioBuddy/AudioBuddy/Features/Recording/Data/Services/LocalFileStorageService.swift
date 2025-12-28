import Foundation

final class LocalFileStorageService: FileStorageService {
    private let fileManager = FileManager.default
    private let recordingsDirectory: URL
    
    init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingsDirectory = documentsPath.appendingPathComponent("Recordings", isDirectory: true)
        
        createRecordingsDirectoryIfNeeded()
    }
    
    // MARK: - FileStorageService
    
    func saveFile(data: Data, name: String) async throws -> URL {
        let fileURL = recordingsDirectory.appendingPathComponent(name)
        
        try data.write(to: fileURL, options: .completeFileProtection)
        
        return fileURL
    }
    
    func deleteFile(at url: URL) async throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }
    
    func fileExists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }
    
    func getFileSize(at url: URL) -> Int64? {
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        return size
    }
    
    // MARK: - Helpers
    
    private func createRecordingsDirectoryIfNeeded() {
        guard !fileManager.fileExists(atPath: recordingsDirectory.path) else { return }
        
        try? fileManager.createDirectory(
            at: recordingsDirectory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )
    }
    
    /// Returns the recordings directory URL for external use
    var recordingsDirectoryURL: URL {
        return recordingsDirectory
    }
}

