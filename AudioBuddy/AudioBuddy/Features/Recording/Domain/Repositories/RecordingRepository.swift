//
//  RecordingRepository.swift
//  AudioBuddy
//
//  Created by Niraj Kale on 15/12/25.
//

import Foundation

protocol RecordingRepository {
    func fetchAll() async throws -> [Recording]
    func save(_ recording: Recording) async throws
    func update(_ recording: Recording) async throws
    func delete(_ recording: Recording) async throws
    func fetch(by id: UUID) async throws -> Recording?
}
