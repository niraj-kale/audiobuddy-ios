import Foundation

protocol FileStorageService {
    func saveFile(data: Data, name: String) async throws -> URL
    func deleteFile(at url: URL) async throws
    func fileExists(at url: URL) -> Bool
    func getFileSize(at url: URL) -> Int64?
}

