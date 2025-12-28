//
//  AudioRecordingService.swift
//  AudioBuddy
//
//  Created by Niraj Kale on 15/12/25.
//

import Foundation

protocol AudioRecordingService {
    func startRecording(to url:URL) async throws
    func stopRecording() async throws
    func resumeRecording() async throws
    func pauseRecording() async throws
    var state: RecordingState { get }
}
