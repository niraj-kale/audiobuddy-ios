//
//  AudioSessionService.swift
//  AudioBuddy
//
//  Created by Niraj Kale on 15/12/25.
//

import Foundation
import AVFoundation

protocol AudioSessionService {
    func requestAuthorization() async throws
    func configure() async throws
    var permissionStatus: AVAudioSession.RecordPermission { get }
}
