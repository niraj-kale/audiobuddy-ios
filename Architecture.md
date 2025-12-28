# VoiceScribe iOS — Architecture

## Overview

VoiceScribe follows **Clean Architecture** principles with **MVVM** (Model-View-ViewModel) pattern, built using **Swift 5.9** and **SwiftUI**. The architecture prioritizes:

- **Privacy**: All processing on-device, zero network transmission
- **Testability**: Clear separation of concerns, dependency injection
- **Modularity**: Feature-based organization for scalability
- **Performance**: Efficient data flow, background processing pipelines

---

## Table of Contents

1. [High-Level Architecture](#1-high-level-architecture)
2. [Layer Responsibilities](#2-layer-responsibilities)
3. [Module Structure](#3-module-structure)
4. [Data Flow](#4-data-flow)
5. [Transcription Pipeline](#5-transcription-pipeline)
6. [State Management](#6-state-management)
7. [Dependency Injection](#7-dependency-injection)
8. [Concurrency Model](#8-concurrency-model)
9. [Data Persistence](#9-data-persistence)
10. [Design Decisions](#10-design-decisions)

---

## 1. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Presentation Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   SwiftUI   │  │   SwiftUI   │  │   SwiftUI   │  │   SwiftUI   │         │
│  │    Views    │  │    Views    │  │    Views    │  │    Views    │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
│         │                │                │                │                │
│  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐         │
│  │  ViewModel  │  │  ViewModel  │  │  ViewModel  │  │  ViewModel  │         │
│  │ @Observable │  │ @Observable │  │ @Observable │  │ @Observable │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
└─────────┼────────────────┼────────────────┼────────────────┼────────────────┘
          │                │                │                │
          └────────────────┴────────┬───────┴────────────────┘
                                    │
┌───────────────────────────────────▼─────────────────────────────────────────┐
│                               Domain Layer                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐              │
│  │    Use Cases    │  │     Entities    │  │   Repositories  │              │
│  │   (Interactors) │  │    (Models)     │  │   (Protocols)   │              │
│  └────────┬────────┘  └─────────────────┘  └────────┬────────┘              │
└───────────┼─────────────────────────────────────────┼───────────────────────┘
            │                                         │
            └─────────────────────┬───────────────────┘
                                  │
┌─────────────────────────────────▼───────────────────────────────────────────┐
│                                Data Layer                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────-┐        │
│  │   SQLite    │  │ File System │  │  Core ML    │  │  AVFoundation│        │
│  │  Database   │  │   Storage   │  │   Models    │  │    Audio     │        │
│  └─────────────┘  └─────────────┘  └─────────────┘  └────────────--┘        │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Dependency Rule

Dependencies point **inward**—outer layers depend on inner layers, never the reverse:

```
Presentation → Domain ← Data
```

The Domain layer has **zero dependencies** on UIKit, SwiftUI, or any Apple framework. This enables:
- Unit testing without simulators
- Swapping implementations (e.g., mock repositories)
- Clear business logic isolation

---

## 2. Layer Responsibilities

### Presentation Layer

| Component        | Responsibility                                        |
|------------------|-------------------------------------------------------|
| **Views**        | Pure UI rendering, user input capture                 |
| **ViewModels**   | UI state management, user action handling, formatting |
| **Coordinators** | Navigation flow (implicit via NavigationStack)        |

```swift
// View: Declarative UI, no business logic
struct RecordingsListView: View {
    @StateObject private var viewModel = RecordingsListViewModel()
    
    var body: some View {
        List(viewModel.recordings) { recording in
            RecordingRowView(recording: recording)
        }
        .task { await viewModel.loadRecordings() }
    }
}

// ViewModel: UI state + use case orchestration
@MainActor
final class RecordingsListViewModel: ObservableObject {
    @Published var recordings: [Recording] = []
    
    private let fetchRecordingsUseCase: FetchRecordingsUseCase
    
    func loadRecordings() async {
        recordings = await fetchRecordingsUseCase.execute()
    }
}
```

### Domain Layer

| Component | Responsibility |
|-----------|----------------|
| **Entities** | Core business objects (Recording, Transcript, Speaker) |
| **Use Cases** | Single-purpose business operations |
| **Repository Protocols** | Abstract data access interfaces |

```swift
// Entity: Pure Swift, no framework dependencies
struct Recording: Identifiable, Hashable {
    let id: UUID
    var title: String
    var duration: TimeInterval
    var transcript: Transcript?
}

// Use Case: Single responsibility
protocol FetchRecordingsUseCase {
    func execute() async -> [Recording]
}

final class FetchRecordingsUseCaseImpl: FetchRecordingsUseCase {
    private let repository: RecordingRepository
    
    func execute() async -> [Recording] {
        await repository.fetchAll(sortedBy: .dateDescending)
    }
}

// Repository Protocol: Abstraction over data source
protocol RecordingRepository {
    func fetchAll(sortedBy: SortOrder) async -> [Recording]
    func save(_ recording: Recording) async throws
    func delete(_ recording: Recording) async throws
}
```

### Data Layer

| Component                      | Responsibility                             |
|--------------------------------|--------------------------------------------|
| **Repository Implementations** | Concrete data access (SQLite, file system) |
| **Data Sources**               | Raw data operations (queries, file I/O)    |
| **Mappers**                    | Entity ↔ DTO conversion                    |

```swift
// Repository Implementation
final class SQLiteRecordingRepository: RecordingRepository {
    private let database: DatabaseManager
    
    func fetchAll(sortedBy: SortOrder) async -> [Recording] {
        let dtos = await database.query(RecordingDTO.self, orderBy: sortedBy)
        return dtos.map { $0.toEntity() }
    }
}

// DTO: Database representation
struct RecordingDTO: Codable {
    let id: String
    let title: String
    let duration: Double
    let createdAt: Date
    
    func toEntity() -> Recording {
        Recording(
            id: UUID(uuidString: id)!,
            title: title,
            duration: duration
        )
    }
}
```

---

## 3. Module Structure

```
VoiceScribe/
├── App/
│   ├── VoiceScribeApp.swift          # @main entry point
│   ├── AppState.swift                 # Global observable state
│   ├── AppDelegate.swift              # UIKit lifecycle hooks
│   └── DependencyContainer.swift      # DI registration
│
├── Core/
│   ├── Audio/
│   │   ├── AudioEngine.swift          # AVAudioEngine wrapper
│   │   ├── AudioProcessor.swift       # DSP preprocessing
│   │   └── AudioSession.swift         # AVAudioSession config
│   │
│   ├── Database/
│   │   ├── DatabaseManager.swift      # SQLite + FTS5 operations
│   │   ├── Migrations/                # Schema migrations
│   │   └── Queries/                   # Type-safe query builders
│   │
│   ├── Models/
│   │   ├── Recording.swift            # Domain entity
│   │   ├── Transcript.swift           # Domain entity
│   │   └── Speaker.swift              # Domain entity
│   │
│   ├── Repositories/
│   │   ├── Protocols/                 # Repository interfaces
│   │   └── Implementations/           # Concrete implementations
│   │
│   ├── Extensions/
│   │   ├── Date+Formatting.swift
│   │   └── TimeInterval+Display.swift
│   │
│   └── Utilities/
│       ├── Logger.swift               # Structured logging
│       └── FileManager+Helpers.swift
│
├── Features/
│   ├── Transcription/
│   │   ├── TranscriptionEngine.swift  # Hybrid ASR coordinator
│   │   ├── AppleSpeechService.swift   # SFSpeechRecognizer wrapper
│   │   ├── WhisperService.swift       # whisper.cpp integration
│   │   └── TranscriptReconciler.swift # Draft/refined merge logic
│   │
│   ├── Diarization/
│   │   ├── SpeakerDiarizer.swift      # Pipeline orchestration
│   │   ├── EmbeddingExtractor.swift   # Speaker embedding model
│   │   └── ClusteringService.swift    # HDBSCAN implementation
│   │
│   ├── AI/
│   │   ├── AIProcessor.swift          # LLM orchestration
│   │   ├── SummarizationService.swift # Phi-3/Llama inference
│   │   └── PromptTemplates.swift      # Structured prompts
│   │
│   ├── Recording/
│   │   ├── Views/
│   │   │   ├── RecordingsListView.swift
│   │   │   ├── RecordingDetailView.swift
│   │   │   └── NewRecordingView.swift
│   │   ├── ViewModels/
│   │   │   ├── RecordingsListViewModel.swift
│   │   │   └── RecordingDetailViewModel.swift
│   │   └── Components/
│   │       ├── WaveformView.swift
│   │       └── TranscriptSegmentView.swift
│   │
│   ├── Search/
│   │   ├── Views/
│   │   │   └── SearchView.swift
│   │   ├── ViewModels/
│   │   │   └── SearchViewModel.swift
│   │   └── SearchEngine.swift         # FTS5 query builder
│   │
│   ├── Editor/
│   │   ├── Views/
│   │   │   └── TranscriptEditorView.swift
│   │   └── ViewModels/
│   │       └── TranscriptEditorViewModel.swift
│   │
│   ├── Export/
│   │   ├── Views/
│   │   │   └── ExportOptionsView.swift
│   │   ├── Exporters/
│   │   │   ├── PlainTextExporter.swift
│   │   │   ├── MarkdownExporter.swift
│   │   │   ├── SRTExporter.swift
│   │   │   └── PDFExporter.swift
│   │   └── ExportCoordinator.swift
│   │
│   └── Settings/
│       ├── Views/
│       │   └── SettingsView.swift
│       └── ViewModels/
│           └── SettingsViewModel.swift
│
└── Resources/
    ├── Assets.xcassets/
    ├── Models/                        # ML model files (.mlmodel, .bin)
    ├── Localizable.strings
    └── Info.plist
```

### Module Dependencies

```
┌────────────────────────────────────────────────────────────┐
│                        Features                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │Recording │ │  Search  │ │  Editor  │ │  Export  │       │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘       │
│       │            │            │            │             │
│       └────────────┴─────┬──────┴────────────┘             │
│                          │                                 │
│  ┌───────────────────────▼────────────────────────────┐    │
│  │              Transcription / AI / Diarization      │    │
│  └───────────────────────┬────────────────────────────┘    │
└──────────────────────────┼─────────────────────────────────┘
                           │
┌──────────────────────────▼─────────────────────────────────┐
│                          Core                              │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │  Audio  │  │Database │  │ Models  │  │  Repos  │        │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘        │
└────────────────────────────────────────────────────────────┘
```

---

## 4. Data Flow

### Unidirectional Data Flow (UDF)

```
┌───────────────────────────────────────────────────────────┐
│                                                           │
│    ┌─────────┐      ┌───────────┐      ┌-─────────┐       │
│    │  View   │──────▶  Action   │─────▶| ViewModel│       │
│    └────▲────┘      └───────────┘      └────┬-────┘       │
│         │                                   │             │
│         │           ┌───────────┐           │             │
│         └───────────│   State   │◀──────────┘             │
│                     └───────────┘                         │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

### Recording Flow Example

```
User taps "Record"
        │
        ▼
┌───────────────────┐
│ NewRecordingView  │  View layer
└─────────┬─────────┘
          │ action: .startRecording
          ▼
┌───────────────────┐
│    AppState      │  State management
│ isRecording=true │
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│   AudioEngine    │  Core audio
│ startRecording() │
└─────────┬─────────┘
          │ audio buffers
          ├─────────────────────────┐
          ▼                         ▼
┌───────────────────┐    ┌───────────────────┐
│   File Writer    │    │TranscriptionEngine│
│  (M4A storage)   │    │   (Real-time)     │
└───────────────────┘    └─────────┬─────────┘
                                   │ partial results
                                   ▼
                         ┌───────────────────┐
                         │    AppState      │
                         │ liveTranscript   │
                         └─────────┬─────────┘
                                   │
                                   ▼
                         ┌───────────────────┐
                         │ NewRecordingView  │
                         │ (UI updates)      │
                         └───────────────────┘
```

---

## 5. Transcription Pipeline

### Hybrid Dual-Pass Architecture

```
                        ┌─────────────────────────────────────┐
                        │           Audio Input               │
                        │      (AVAudioEngine tap)            │
                        └──────────────┬──────────────────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                  │                  │
                    ▼                  ▼                  ▼
         ┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐
         │  Pass 1: Apple   │ │  Ring Buffer │ │   File Writer    │
         │  Speech Framework│ │  (for Whisper)│ │   (M4A storage)  │
         │  ~300ms latency  │ │              │ │                  │
         └────────┬─────────┘ └──────┬───────┘ └──────────────────┘
                  │                  │
                  │                  │ (on recording stop)
                  ▼                  ▼
         ┌──────────────────┐ ┌──────────────────┐
         │  Draft Transcript│ │  Pass 2: Whisper │
         │  (immediate UI)  │ │  (background)    │
         └────────┬─────────┘ └────────┬─────────┘
                  │                    │
                  │                    ▼
                  │           ┌──────────────────┐
                  │           │ Refined Transcript│
                  │           │ (word timestamps) │
                  │           └────────┬─────────┘
                  │                    │
                  └──────────┬─────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │ Transcript Reconciler │
                  │ • Preserve user edits │
                  │ • Merge improvements  │
                  │ • Animate UI updates  │
                  └──────────┬───────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │  Speaker Diarization │
                  │  (post-processing)   │
                  └──────────┬───────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │   Final Transcript   │
                  │  with speaker labels │
                  └──────────────────────┘
```

### Component Responsibilities

| Component | Engine | Latency | Output |
|-----------|--------|---------|--------|
| **Pass 1** | SFSpeechRecognizer | ~300ms | Draft text (streaming) |
| **Pass 2** | whisper.cpp + CoreML | 3-10x RT | Refined text + word timestamps |
| **Reconciler** | Custom diff algorithm | <100ms | Merged transcript |
| **Diarizer** | ResNet + HDBSCAN | ~2x RT | Speaker labels |

### Transcript Reconciliation Algorithm

```swift
func reconcile(draft: Transcript, refined: Transcript, userEdits: Set<UUID>) -> Transcript {
    var result = refined
    
    for (segmentIndex, segment) in result.segments.enumerated() {
        for (wordIndex, word) in segment.words.enumerated() {
            // Find corresponding draft word by timestamp proximity
            guard let draftWord = draft.word(near: word.startTime, tolerance: 0.5) else {
                continue
            }
            
            // Preserve user edits (pinned words)
            if userEdits.contains(draftWord.id) {
                result.segments[segmentIndex].words[wordIndex] = TranscriptWord(
                    id: word.id,
                    text: draftWord.text,           // Keep user's edit
                    startTime: word.startTime,      // Use Whisper's timing
                    endTime: word.endTime,
                    confidence: word.confidence,
                    originalText: word.text         // Track what Whisper suggested
                )
                result.segments[segmentIndex].isPinned = true
            }
        }
    }
    
    return result
}
```

---

## 6. State Management

### Global State (AppState)

Single source of truth for cross-cutting concerns:

```swift
@MainActor
final class AppState: ObservableObject {
    // Recording state
    @Published var isRecording = false
    @Published var currentRecordingID: UUID?
    @Published var liveTranscript = ""
    
    // Processing state
    @Published var processingQueue: [ProcessingTask] = []
    
    // Settings
    @Published var whisperModel: WhisperModel = .base
    @Published var autoTranscribe = true
    
    // Error handling
    @Published var currentError: AppError?
}
```

### Feature State (ViewModels)

Scoped state for individual features:

```swift
@MainActor
final class RecordingDetailViewModel: ObservableObject {
    @Published var recording: Recording
    @Published var isPlaying = false
    @Published var playbackPosition: TimeInterval = 0
    @Published var selectedSegment: TranscriptSegment?
    
    // Injected dependencies
    private let audioEngine: AudioEngine
    private let repository: RecordingRepository
}
```

### State Flow

```
┌────────────────────────────────────────────────────────────┐
│                       AppState                             │
│            (Global, injected via Environment)              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Recording  │  │  Processing │  │   Settings  │         │
│  │    State    │  │    Queue    │  │    State    │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└────────────────────────────┬───────────────────────────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────┐ ┌─────────────────┐ ┌────────────────-─┐
│RecordingsListVM │ │RecordingDetailVM│ │  SearchViewModel │
│  (list state)   │ │ (detail state)  │ │ (search state)   │
└─────────────────┘ └─────────────────┘ └─────────────────-┘
```

---

## 7. Dependency Injection

### Container Pattern

```swift
final class DependencyContainer {
    static let shared = DependencyContainer()
    
    // MARK: - Core Services
    
    lazy var databaseManager: DatabaseManager = {
        DatabaseManager(path: documentsPath.appendingPathComponent("voicescribe.db"))
    }()
    
    lazy var audioEngine: AudioEngine = {
        AudioEngine()
    }()
    
    // MARK: - Repositories
    
    lazy var recordingRepository: RecordingRepository = {
        SQLiteRecordingRepository(database: databaseManager)
    }()
    
    lazy var speakerRepository: SpeakerRepository = {
        SQLiteSpeakerRepository(database: databaseManager)
    }()
    
    // MARK: - Use Cases
    
    lazy var fetchRecordingsUseCase: FetchRecordingsUseCase = {
        FetchRecordingsUseCaseImpl(repository: recordingRepository)
    }()
    
    // MARK: - Feature Services
    
    lazy var transcriptionEngine: TranscriptionEngine = {
        TranscriptionEngine(
            speechService: AppleSpeechService(),
            whisperService: WhisperService(model: .base)
        )
    }()
}
```

### Environment Injection

```swift
@main
struct VoiceScribeApp: App {
    @StateObject private var appState = AppState()
    
    private let container = DependencyContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(container.audioEngine)
                .environmentObject(container.transcriptionEngine)
        }
    }
}
```

### Protocol-Based Injection (for Testing)

```swift
// Protocol
protocol TranscriptionService {
    func transcribe(audio: URL) async throws -> Transcript
}

// Production implementation
final class WhisperTranscriptionService: TranscriptionService {
    func transcribe(audio: URL) async throws -> Transcript { ... }
}

// Test mock
final class MockTranscriptionService: TranscriptionService {
    var mockResult: Transcript?
    
    func transcribe(audio: URL) async throws -> Transcript {
        return mockResult ?? Transcript()
    }
}
```

---

## 8. Concurrency Model

### Swift Concurrency Integration

```swift
// Actor for thread-safe audio buffer access
actor AudioBufferManager {
    private var buffers: [[Float]] = []
    
    func append(_ buffer: [Float]) {
        buffers.append(buffer)
    }
    
    func flush() -> [[Float]] {
        defer { buffers.removeAll() }
        return buffers
    }
}

// MainActor for UI state
@MainActor
final class RecordingDetailViewModel: ObservableObject {
    @Published var transcript: Transcript?
    
    func loadTranscript() async {
        // Runs on MainActor, safe to update @Published
        transcript = await repository.fetchTranscript(for: recordingID)
    }
}

// Background processing with Task groups
func processRecording(_ recording: Recording) async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
        // Parallel processing
        group.addTask { try await self.runWhisperTranscription(recording) }
        group.addTask { try await self.extractSpeakerEmbeddings(recording) }
        
        try await group.waitForAll()
    }
    
    // Sequential: diarization needs both results
    await runDiarization(recording)
}
```

### Background Processing Queue

```swift
actor ProcessingQueue {
    private var tasks: [ProcessingTask] = []
    private var isProcessing = false
    
    func enqueue(_ task: ProcessingTask) async {
        tasks.append(task)
        await processNextIfNeeded()
    }
    
    private func processNextIfNeeded() async {
        guard !isProcessing, let task = tasks.first else { return }
        
        isProcessing = true
        tasks.removeFirst()
        
        do {
            try await task.execute()
            await MainActor.run { task.onComplete?(.success(())) }
        } catch {
            await MainActor.run { task.onComplete?(.failure(error)) }
        }
        
        isProcessing = false
        await processNextIfNeeded()
    }
}
```

---

## 9. Data Persistence

### SQLite Schema

```sql
-- Recordings table
CREATE TABLE recordings (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    duration REAL NOT NULL,
    audio_path TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    folder_id TEXT REFERENCES folders(id),
    is_starred INTEGER DEFAULT 0,
    calendar_event_id TEXT,
    location_lat REAL,
    location_lng REAL,
    location_name TEXT
);

-- Transcripts with FTS5 for search
CREATE VIRTUAL TABLE transcripts_fts USING fts5(
    content,
    recording_id UNINDEXED,
    tokenize='porter'
);

-- Transcript segments
CREATE TABLE transcript_segments (
    id TEXT PRIMARY KEY,
    recording_id TEXT REFERENCES recordings(id) ON DELETE CASCADE,
    speaker_id TEXT REFERENCES speakers(id),
    start_time REAL NOT NULL,
    end_time REAL NOT NULL,
    text TEXT NOT NULL,
    is_edited INTEGER DEFAULT 0,
    is_pinned INTEGER DEFAULT 0,
    sequence_order INTEGER NOT NULL
);

-- Words with timing
CREATE TABLE transcript_words (
    id TEXT PRIMARY KEY,
    segment_id TEXT REFERENCES transcript_segments(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    start_time REAL NOT NULL,
    end_time REAL NOT NULL,
    confidence REAL DEFAULT 1.0,
    original_text TEXT,
    sequence_order INTEGER NOT NULL
);

-- Speaker profiles
CREATE TABLE speakers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    color TEXT NOT NULL,
    embedding BLOB,
    contact_id TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_speaking_time REAL DEFAULT 0
);

-- Indexes
CREATE INDEX idx_recordings_created ON recordings(created_at DESC);
CREATE INDEX idx_segments_recording ON transcript_segments(recording_id);
CREATE INDEX idx_words_segment ON transcript_words(segment_id);
```

### File System Structure

```
Documents/
├── voicescribe.db              # SQLite database
├── recordings/
│   ├── {uuid}.m4a              # Audio files
│   └── {uuid}.m4a
└── exports/
    └── temp/                   # Temporary export files

Application Support/
├── models/
│   ├── ggml-base.bin           # Whisper model
│   ├── speaker-encoder.mlmodel # Speaker embedding
│   └── phi-3-mini-4bit.gguf    # LLM for summaries
└── cache/
    └── thumbnails/             # Waveform cache
```

---

## 10. Design Decisions

### Why Hybrid Transcription?

| Approach | Latency | Accuracy | UX |
|----------|---------|----------|-----|
| Apple Speech only | ~300ms | Moderate | Good real-time feedback |
| Whisper only | 3-10s chunks | High | Poor real-time experience |
| **Hybrid** | ~300ms + background | High | Best of both worlds |

**Decision**: Users need immediate feedback while recording. Apple Speech provides this, while Whisper refines in the background. The reconciliation step preserves user edits.

### Why SQLite + FTS5?

| Option | Search Speed | Full-Text | Encryption | On-Device |
|--------|--------------|-----------|------------|-----------|
| Core Data | Fast | Via Spotlight | Limited | ✓ |
| SQLite + FTS5 | Very Fast | Built-in | SQLCipher | ✓ |
| CloudKit | Varies | Limited | Apple | ✗ |

**Decision**: FTS5 provides sub-100ms full-text search across thousands of transcripts. SQLCipher adds AES-256 encryption. No cloud dependency.

### Why MVVM over TCA/Redux?

| Pattern | Complexity | Learning Curve | SwiftUI Fit |
|---------|------------|----------------|-------------|
| MVVM | Low | Low | Native |
| TCA | High | High | Good |
| Redux-like | Medium | Medium | Requires adapters |

**Decision**: MVVM aligns naturally with SwiftUI's `@ObservableObject` and `@StateObject`. The app's state complexity doesn't warrant TCA's overhead. Unidirectional flow is achieved through careful ViewModel design.

### Why Actor-Based Concurrency?

**Decision**: Swift's actor model provides compile-time data race safety. Critical for audio buffer management where multiple threads (audio callback, UI, ML inference) access shared state.

```swift
// Without actors: race condition risk
class UnsafeBufferManager {
    var buffers: [[Float]] = []  // Not thread-safe!
}

// With actors: guaranteed safety
actor SafeBufferManager {
    var buffers: [[Float]] = []  // Isolated, safe
}
```

---

## Appendix: Testing Strategy

### Unit Tests

```swift
// ViewModel tests with mock repository
final class RecordingsListViewModelTests: XCTestCase {
    var sut: RecordingsListViewModel!
    var mockRepository: MockRecordingRepository!
    
    override func setUp() {
        mockRepository = MockRecordingRepository()
        sut = RecordingsListViewModel(repository: mockRepository)
    }
    
    func testLoadRecordings_sortsbyDateDescending() async {
        mockRepository.mockRecordings = [
            Recording(title: "Old", createdAt: .distantPast),
            Recording(title: "New", createdAt: .now)
        ]
        
        await sut.loadRecordings()
        
        XCTAssertEqual(sut.recordings.first?.title, "New")
    }
}
```

### Integration Tests

```swift
// Database integration tests
final class RecordingRepositoryIntegrationTests: XCTestCase {
    var database: DatabaseManager!
    var repository: SQLiteRecordingRepository!
    
    override func setUp() {
        database = DatabaseManager(inMemory: true)
        repository = SQLiteRecordingRepository(database: database)
    }
    
    func testSaveAndFetch_roundTrip() async throws {
        let recording = Recording(title: "Test")
        
        try await repository.save(recording)
        let fetched = await repository.fetchAll(sortedBy: .dateDescending)
        
        XCTAssertEqual(fetched.first?.id, recording.id)
    }
}
```

### UI Tests

```swift
// SwiftUI Preview tests
struct RecordingsListView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingsListView()
            .environmentObject(AppState())
            .environmentObject(MockAudioEngine())
    }
}
```

---

*Architecture documentation v1.0 — VoiceScribe iOS*
