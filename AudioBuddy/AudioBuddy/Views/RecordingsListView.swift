//
//  RecordingsListView.swift
//  AudioBuddy
//
//  Displays list of all saved recordings stored locally.
//  No cloud sync - all recordings stay on device.
//

import SwiftUI

struct RecordingsListView: View {
    @StateObject private var recordingsManager = RecordingsManager()
    @State private var selectedRecording: Recording?
    
    var body: some View {
        NavigationStack {
            Group {
                if recordingsManager.recordings.isEmpty {
                    emptyStateView
                } else {
                    recordingsList
                }
            }
            .navigationTitle("Recordings")
            .sheet(item: $selectedRecording) { recording in
                AudioPlayerView(recording: recording)
            }
            .onAppear {
                recordingsManager.loadRecordings()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Recordings Yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Tap the Record tab to create your first recording.\nAll recordings are stored privately on your device.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var recordingsList: some View {
        List {
            ForEach(recordingsManager.recordings) { recording in
                Button {
                    selectedRecording = recording
                } label: {
                    RecordingRow(recording: recording)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: recordingsManager.deleteRecording)
        }
        .listStyle(.insetGrouped)
        .toolbar {
            EditButton()
        }
    }
}

struct RecordingRow: View {
    let recording: Recording
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.formattedDate)
                    .font(.headline)
                
                Text(recording.formattedDuration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RecordingsListView()
}
