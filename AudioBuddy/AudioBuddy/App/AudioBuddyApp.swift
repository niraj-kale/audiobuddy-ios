//
//  AudioBuddyApp.swift
//  AudioBuddy
//
//  Created by Niraj Kale on 04/12/25.
//

import SwiftUI
import AVFoundation

@main
struct AudioBuddyApp: App {
    @StateObject private var container = DependencyContainer()
    @State private var showPermissionAlert = false
    
    init() {
        setupDatabase()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
                .task {
                    await configureAudioSession()
                }
                .alert("Microphone Permission Required", isPresented: $showPermissionAlert) {
                    Button("Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Please enable microphone access in Settings to record audio.")
                }
        }
    }
    
    private func setupDatabase() {
        do {
            try DatabaseManager.shared.setup()
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }
    
    private func configureAudioSession() async {
        let status = container.audioSessionService.permissionStatus
        if status == .undetermined {
            do {
                try await container.audioSessionService.requestAuthorization()
            } catch {
                showPermissionAlert = true
            }
        } else if status == .denied {
            showPermissionAlert = true
        }
    }
}
