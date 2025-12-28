import SwiftUI

struct RecordingsListView: View {
    @EnvironmentObject private var container: DependencyContainer
    @State private var showRecordingView = false
    @State private var recordings: [Recording] = []
    @State private var sortOrder: RecordingSortOrder = .dateDescending
    @State private var recordingToDelete: Recording?
    @State private var recordingToRename: Recording?
    @State private var newTitle: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                if recordings.isEmpty {
                    emptyState
                } else {
                    recordingsList
                }
                
                floatingRecordButton
            }
            .navigationTitle("Recordings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    sortMenu
                }
            }
            .fullScreenCover(isPresented: $showRecordingView, onDismiss: loadRecordings) {
                NavigationStack {
                    RecordingView(viewModel: makeRecordingViewModel())
                        .environmentObject(container)
                        .navigationTitle("New Recording")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") {
                                    showRecordingView = false
                                }
                            }
                        }
                }
            }
            .alert("Delete Recording?", isPresented: .init(
                get: { recordingToDelete != nil },
                set: { if !$0 { recordingToDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let recording = recordingToDelete {
                        deleteRecording(recording)
                    }
                }
                Button("Cancel", role: .cancel) {
                    recordingToDelete = nil
                }
            } message: {
                Text("This recording and its audio file will be permanently deleted.")
            }
            .alert("Rename Recording", isPresented: .init(
                get: { recordingToRename != nil },
                set: { if !$0 { recordingToRename = nil } }
            )) {
                TextField("Title", text: $newTitle)
                Button("Save") {
                    if let recording = recordingToRename {
                        renameRecording(recording, to: newTitle)
                    }
                }
                Button("Cancel", role: .cancel) {
                    recordingToRename = nil
                }
            }
            .task {
                loadRecordings()
            }
        }
    }
    
    // MARK: - Sort Menu
    private var sortMenu: some View {
        Menu {
            Button {
                sortOrder = .dateDescending
                loadRecordings()
            } label: {
                HStack {
                    Text("Newest First")
                    if sortOrder == .dateDescending { Image(systemName: "checkmark") }
                }
            }
            
            Button {
                sortOrder = .dateAscending
                loadRecordings()
            } label: {
                HStack {
                    Text("Oldest First")
                    if sortOrder == .dateAscending { Image(systemName: "checkmark") }
                }
            }
            
            Divider()
            
            Button {
                sortOrder = .titleAscending
                loadRecordings()
            } label: {
                HStack {
                    Text("Title A-Z")
                    if sortOrder == .titleAscending { Image(systemName: "checkmark") }
                }
            }
            
            Button {
                sortOrder = .titleDescending
                loadRecordings()
            } label: {
                HStack {
                    Text("Title Z-A")
                    if sortOrder == .titleDescending { Image(systemName: "checkmark") }
                }
            }
            
            Divider()
            
            Button {
                sortOrder = .durationDescending
                loadRecordings()
            } label: {
                HStack {
                    Text("Longest First")
                    if sortOrder == .durationDescending { Image(systemName: "checkmark") }
                }
            }
            
            Button {
                sortOrder = .durationAscending
                loadRecordings()
            } label: {
                HStack {
                    Text("Shortest First")
                    if sortOrder == .durationAscending { Image(systemName: "checkmark") }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform")
                .font(.system(size: 60))
                .foregroundColor(Theme.secondaryColor)
            
            Text("No Recordings")
                .font(Theme.Typography.title)
            
            Text("Start recording to see your audio files here")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.secondaryColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Recordings List
    private var recordingsList: some View {
        List {
            ForEach(recordings) { recording in
                RecordingRowView(recording: recording)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            recordingToDelete = recording
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            newTitle = recording.title
                            recordingToRename = recording
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
            }
        }
        .listStyle(.plain)
        .refreshable {
            loadRecordings()
        }
    }
    
    // MARK: - Floating Record Button
    private var floatingRecordButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    showRecordingView = true
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(Color.red))
                        .shadow(color: .red.opacity(0.4), radius: 8, y: 4)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Actions
    private func loadRecordings() {
        Task {
            do {
                recordings = try await container.fetchRecordingsUseCase.execute(sortOrder: sortOrder)
            } catch {
                Logger.error("Failed to load recordings", error: error, category: .recording)
            }
        }
    }
    
    private func deleteRecording(_ recording: Recording) {
        Task {
            do {
                try await container.deleteRecordingUseCase.execute(recording)
                loadRecordings()
            } catch {
                Logger.error("Failed to delete recording", error: error, category: .recording)
            }
        }
    }
    
    private func renameRecording(_ recording: Recording, to title: String) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        Task {
            do {
                try await container.updateRecordingTitleUseCase.execute(recording: recording, newTitle: title)
                loadRecordings()
            } catch {
                Logger.error("Failed to rename recording", error: error, category: .recording)
            }
        }
    }
    
    private func makeRecordingViewModel() -> RecordingViewModel {
        RecordingViewModel(
            startRecordingUseCase: container.startRecordingUseCase,
            stopRecordingUseCase: container.stopRecordingUseCase,
            audioSessionService: container.audioSessionService,
            recordingRepository: container.recordingRepository
        )
    }
}

// MARK: - Recording Row View
struct RecordingRowView: View {
    let recording: Recording
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.system(size: 20))
                .foregroundColor(Theme.primaryColor)
                .frame(width: 44, height: 44)
                .background(Theme.primaryColor.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.title)
                    .font(Theme.Typography.body)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(formattedDate)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.secondaryColor)
                    
                    Text("•")
                        .foregroundColor(Theme.secondaryColor)
                    
                    Text(formattedDuration)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.secondaryColor)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Theme.secondaryColor)
        }
        .padding(.vertical, 4)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: recording.date)
    }
    
    private var formattedDuration: String {
        let minutes = Int(recording.duration) / 60
        let seconds = Int(recording.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
