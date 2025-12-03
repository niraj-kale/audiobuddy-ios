//
//  RecordingView.swift
//  AudioBuddy
//
//  Main view for recording audio.
//  Provides a simple interface with record/stop controls.
//

import SwiftUI

struct RecordingView: View {
    @StateObject private var recorder = AudioRecorderManager()
    @StateObject private var recordingsManager = RecordingsManager()
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                // Recording status indicator
                VStack(spacing: 16) {
                    if recorder.isRecording {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                            .modifier(PulsingAnimation())
                        
                        Text("Recording...")
                            .font(.title2)
                            .foregroundColor(.red)
                        
                        Text(recorder.formattedDuration)
                            .font(.system(size: 48, weight: .medium, design: .monospaced))
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 20, height: 20)
                        
                        Text("Ready to Record")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("00:00")
                            .font(.system(size: 48, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Permission warning
                if !recorder.hasPermission {
                    VStack(spacing: 12) {
                        Image(systemName: "mic.slash.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("Microphone Access Required")
                            .font(.headline)
                        
                        Text("Please grant microphone permission in Settings to record audio.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Open Settings") {
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsURL)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
                
                // Record button
                Button(action: toggleRecording) {
                    ZStack {
                        Circle()
                            .fill(recorder.isRecording ? Color.red.opacity(0.2) : Color.red.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .stroke(Color.red, lineWidth: 4)
                            .frame(width: 100, height: 100)
                        
                        if recorder.isRecording {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red)
                                .frame(width: 36, height: 36)
                        } else {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 72, height: 72)
                        }
                    }
                }
                .disabled(!recorder.hasPermission)
                .opacity(recorder.hasPermission ? 1.0 : 0.5)
                
                // Recording actions when recording
                if recorder.isRecording {
                    Button(role: .destructive) {
                        recorder.cancelRecording()
                    } label: {
                        Label("Cancel Recording", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                // Stats
                VStack(spacing: 4) {
                    Text("\(recordingsManager.recordings.count) recordings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Total: \(recordingsManager.formattedTotalDuration)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Audio Buddy")
            .alert("Recording Saved", isPresented: $showingSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your recording has been saved locally.")
            }
            .alert("Error", isPresented: .init(
                get: { recorder.errorMessage != nil },
                set: { if !$0 { recorder.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {
                    recorder.errorMessage = nil
                }
            } message: {
                Text(recorder.errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private func toggleRecording() {
        if recorder.isRecording {
            // Stop recording and save
            if let result = recorder.stopRecording() {
                recordingsManager.saveRecording(url: result.url, duration: result.duration)
                showingSaveConfirmation = true
            }
        } else {
            // Start recording
            _ = recorder.startRecording()
        }
    }
}

// Pulsing animation for recording indicator
struct PulsingAnimation: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .opacity(isAnimating ? 0.8 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    RecordingView()
}
