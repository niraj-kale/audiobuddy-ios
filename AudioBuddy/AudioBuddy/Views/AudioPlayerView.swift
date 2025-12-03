//
//  AudioPlayerView.swift
//  AudioBuddy
//
//  Playback view for recorded audio files.
//  All playback is local - no streaming.
//

import SwiftUI

struct AudioPlayerView: View {
    let recording: Recording
    
    @StateObject private var player = AudioPlayerManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Recording info
                VStack(spacing: 8) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)
                    
                    Text(recording.formattedDate)
                        .font(.title2)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Progress
                VStack(spacing: 8) {
                    Slider(
                        value: Binding(
                            get: { player.progress },
                            set: { newValue in
                                player.seek(to: newValue * player.duration)
                            }
                        ),
                        in: 0...1
                    )
                    .tint(.accentColor)
                    
                    HStack {
                        Text(player.formattedCurrentTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(player.formattedDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Playback controls
                HStack(spacing: 40) {
                    // Rewind 15 seconds
                    Button {
                        let newTime = max(0, player.currentTime - 15)
                        player.seek(to: newTime)
                    } label: {
                        Image(systemName: "gobackward.15")
                            .font(.title)
                    }
                    
                    // Play/Pause
                    Button {
                        player.togglePlayPause()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 72))
                    }
                    
                    // Forward 15 seconds
                    Button {
                        let newTime = min(player.duration, player.currentTime + 15)
                        player.seek(to: newTime)
                    } label: {
                        Image(systemName: "goforward.15")
                            .font(.title)
                    }
                }
                .foregroundColor(.accentColor)
                
                Spacer()
                
                // Privacy indicator
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                    Text("Stored locally on your device")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Playback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        player.stop()
                        dismiss()
                    }
                }
            }
            .onAppear {
                player.loadAudio(url: recording.fileURL)
            }
            .onDisappear {
                player.stop()
            }
            .alert("Error", isPresented: .init(
                get: { player.errorMessage != nil },
                set: { if !$0 { player.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {
                    player.errorMessage = nil
                }
            } message: {
                Text(player.errorMessage ?? "An unknown error occurred")
            }
        }
    }
}

#Preview {
    AudioPlayerView(recording: Recording(
        filename: "test.m4a",
        duration: 125
    ))
}
