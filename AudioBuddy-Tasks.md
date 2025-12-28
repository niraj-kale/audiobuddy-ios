# AudioBuddy iOS — Development Tasks

> **UI-First Vertical Slicing + Clean Architecture**
> 
> Each feature is organized as **end-to-end steps**:
> - **Step 1:** UI (Static → Mock) — See it working first
> - **Step 2+:** Domain + Data — Build supporting infrastructure
> - **Manual Test:** After each step before proceeding
> 
> **Layers:** Presentation → Domain ← Data (dependencies point inward)

---

## Current Implementation Status

> **Analysis Date:** December 28, 2025
> 
> **Current State:** Features 1-3 complete. Recording, persistence, and list management working end-to-end.
> 
> **✅ Feature 1: Project Foundation** — Complete
> **✅ Feature 2: Audio Recording** — Complete (record, save, persist to SQLite)
> **✅ Feature 3: Recordings List** — Complete (list, delete, rename, sort)
> 
> **⏳ Next:** Feature 4 (Audio Playback)
> 
> **❌ Not Yet Implemented:**
> - Audio playback (Feature 4)
> - SQLCipher encryption (optional)

---

## Folder Structure

```
AudioBuddy/
├── App/                          # App entry point, DI container
├── Features/
│   └── Recording/
│       ├── Domain/               # Entities, UseCases, Protocols
│       ├── Data/                 # Repositories, DTOs, Services
│       └── Presentation/         # Views, ViewModels
├── Core/                         # Shared infrastructure (Database)
└── Views/                        # Legacy views (migrating to Features/)
```

---

## Feature 1: Project Foundation ✅
**Deliverable:** App launches with navigation shell and clean architecture structure

> **✅ Status:** Complete

---

### Step 1: Xcode Project Setup
- [x] Bundle ID, code signing, build schemes
- [x] Folder structure — `Features/`, `App/`, `Core/`
- [x] Background Modes (audio) capability
- [x] Info.plist — Microphone, Speech Recognition permissions
- [x] iOS 16+ deployment target

### Step 2: App Shell & Navigation
- [x] `AppState` — Global state — `App/AppState.swift`
- [x] Tab navigation (Recordings, Search, Settings) — `ContentView.swift`
- [x] `RecordingsListView`, `SettingsView` — `Views/`
- [x] Theme (colors, typography) — `Theme.swift`
- [x] Reusable components — `Card.swift`, `PrimaryButton.swift`

### Step 3: Dependency Injection
- [x] `DependencyContainer` — `App/DependencyContainer.swift`
- [x] Environment object injection in `AudioBuddyApp`
- [x] **✅ MANUAL TEST:** App launches with tabs

---

## Feature 2: Audio Recording ✅
**Deliverable:** User can record audio and recordings persist across app launches
**Depends on:** Feature 1

> **✅ Status:** Complete

---

### Step 1: Recording UI (End-to-End)
**Flow:** RecordingView → RecordingViewModel → StartRecordingUseCase → AVAudioRecordingService

- [x] **UI:** `RecordingView` — Record button, timer, pause/stop buttons — `Presentation/Views/RecordingView.swift`
- [x] **ViewModel:** `RecordingViewModel` — State management, timer, permission handling — `Presentation/ViewModels/RecordingViewModel.swift`
- [x] **Domain:** `StartRecordingUseCase`, `StopRecordingUseCase` — `Domain/UseCases/`
- [x] **Domain:** `Recording` entity, `RecordingState` enum — `Domain/Entities/`
- [x] **Domain:** Protocols — `RecordingRepository`, `AudioRecordingService`, `AudioSessionService`
- [x] **Data:** `AVAudioRecordingService` — AVAudioEngine, 48kHz mono M4A — `Data/Services/`
- [x] **Data:** `AVAudioSessionService` — Permissions, audio session config — `Data/Services/`
- [x] **Wire:** `DependencyContainer` — All services and use cases registered
- [x] **✅ MANUAL TEST:** Record audio, timer counts, file created

---

### Step 2: Persistence (End-to-End)
**Flow:** Recording saved → SQLiteRepository → GRDB → Database file

- [x] **Domain:** `FetchRecordingsUseCase` with `RecordingSortOrder` — `Domain/UseCases/`
- [x] **Domain:** `FileStorageService` protocol — `Domain/Services/`
- [x] **Data:** `LocalFileStorageService` — Documents/Recordings, file protection — `Data/Services/`
- [x] **Data:** `DatabaseManager` — GRDB singleton, migrations — `Core/Database/`
- [x] **Data:** `RecordingDTO`, `RecordingMapper` — `Data/DTOs/`, `Data/Mappers/`
- [x] **Data:** `SQLiteRecordingRepository` — CRUD operations — `Data/Repositories/`
- [x] **Wire:** Replace InMemoryRepository with SQLiteRepository in DependencyContainer
- [x] **✅ MANUAL TEST:** Record → Kill app → Relaunch → Recording persists

---

### Step 3: Encryption (Optional - Future)
- [ ] Integrate SQLCipher for database encryption
- [ ] Keychain-based encryption key management
- [ ] **✅ MANUAL TEST:** Database file is encrypted

---

## Feature 3: Recordings List ✅
**Deliverable:** Browse and manage saved recordings
**Depends on:** Feature 2

> **✅ Status:** Complete

---

### Step 1: List Display (End-to-End)
**Flow:** RecordingsListView → FetchRecordingsUseCase → SQLiteRepository

- [x] **UI:** `RecordingRowView` — Title, date, duration — `Views/RecordingsListView.swift`
- [x] **UI:** `RecordingsListView` — List with empty state, floating record button
- [x] **UI:** Pull-to-refresh
- [x] **Domain:** `FetchRecordingsUseCase` — Already exists from Feature 2
- [x] **Wire:** View calls UseCase via DependencyContainer
- [x] **✅ MANUAL TEST:** List shows recordings, empty state when none

---

### Step 2: Delete Recording (End-to-End)
**Flow:** Swipe → DeleteRecordingUseCase → Repository + File deletion

- [x] **UI:** Swipe-to-delete with confirmation alert — `RecordingsListView.swift`
- [x] **Domain:** `DeleteRecordingUseCase` — `Domain/UseCases/DeleteRecordingUseCase.swift`
- [x] **Data:** Repository `delete()` + FileManager deletion in UseCase
- [x] **Wire:** UseCase in `DependencyContainer`, called from View
- [ ] **✅ MANUAL TEST:** Swipe → Delete → Recording + audio file removed

---

### Step 3: Rename Recording (End-to-End)
**Flow:** Swipe → UpdateRecordingTitleUseCase → Repository update

- [x] **UI:** Swipe → Rename button → Alert with TextField — `RecordingsListView.swift`
- [x] **Domain:** `UpdateRecordingTitleUseCase` — `Domain/UseCases/UpdateRecordingTitleUseCase.swift`
- [x] **Data:** Repository `update()` method — `SQLiteRecordingRepository.swift`
- [x] **Wire:** UseCase in `DependencyContainer`, called from View
- [ ] **✅ MANUAL TEST:** Swipe → Rename → New title appears in list

---

### Step 4: Sort Options (End-to-End)
**Flow:** Toolbar menu → FetchRecordingsUseCase with sort order

- [x] **UI:** Sort menu in toolbar (6 options) — `RecordingsListView.swift`
- [x] **Domain:** `RecordingSortOrder` enum — Already exists
- [x] **Wire:** Sort order passed to UseCase on selection
- [ ] **✅ MANUAL TEST:** Change sort → List reorders correctly

---

## Feature 4: Audio Playback
**Deliverable:** Play back any recording with transport controls
**Depends on:** Feature 3

> **⏳ Status:** Not started

---

### Step 1: Player UI (Static → Mock)
**Goal:** See player UI working with mock playback

- [ ] **UI:** Create `PlayerView` — Play/pause, progress slider, time labels, skip ±15s
- [ ] **UI:** Create `MiniPlayerView` — Title, play/pause, tap to expand
- [ ] **ViewModel:** Create `PlaybackViewModel` with mock state:
  - `@Published var isPlaying: Bool`
  - `@Published var currentTime: TimeInterval`
  - `@Published var duration: TimeInterval`
  - Mock `play()`, `pause()`, `seek(to:)`, `skip(seconds:)`
  - Timer to simulate progress
- [ ] **Wire:** Connect Views to ViewModel
- [ ] **✅ MANUAL TEST:** Tap play → timer runs, progress updates, controls work

---

### Step 2: Real Playback (End-to-End)
**Flow:** PlayerView → PlaybackViewModel → StartPlaybackUseCase → AVAudioPlaybackService

- [ ] **Domain:** `PlaybackState` enum (stopped, playing, paused)
- [ ] **Domain:** `AudioPlaybackService` protocol — play, pause, seek, state
- [ ] **Domain:** `StartPlaybackUseCase`, `SeekPlaybackUseCase`
- [ ] **Data:** `AVAudioPlaybackService` — AVAudioPlayer wrapper
- [ ] **Wire:** Inject service and use cases into ViewModel
- [ ] **Wire:** Replace mock timer with real playback updates
- [ ] **✅ MANUAL TEST:** Tap recording → audio plays, slider tracks progress

---

### Step 3: Navigation & Integration
**Goal:** Seamless playback from recordings list

- [ ] **UI:** Add MiniPlayerView to main navigation (bottom bar)
- [ ] **UI:** Tap row in RecordingsListView → starts playback
- [ ] **UI:** Tap MiniPlayer → expands to full PlayerView
- [ ] **Wire:** Handle playback completion (reset state)
- [ ] **✅ MANUAL TEST:** Complete flow: List → Tap → Play → Scrub → Stop

---

## Feature 5: Background Recording
**Deliverable:** Recording continues when app is backgrounded
**Depends on:** Feature 2

> **⏳ Status:** Not started

---

### Step 1: Background Indicator UI
**Goal:** User knows recording continues in background

- [ ] **UI:** Add "Recording in background" banner to RecordingView
- [ ] **UI:** Show local notification when recording in background
- [ ] **✅ MANUAL TEST:** Background app → banner shows, notification appears

---

### Step 2: Interruption Handling (End-to-End)
**Flow:** Phone call → Audio session interrupted → Auto-pause → Resume

- [ ] **Domain:** Extend `AudioRecordingService` — `handleInterruption()`, `handleRouteChange()`
- [ ] **Data:** Handle audio session interruptions (phone calls, alarms)
- [ ] **Data:** Handle route changes (headphones disconnect)
- [ ] **Data:** Auto-pause on interruption, resume when available
- [ ] **✅ MANUAL TEST:** Simulate phone call → recording pauses → resumes

---

### Step 3: Reliability & Recovery
**Goal:** Never lose recording data

- [ ] **Data:** Handle memory warnings with buffer flushing
- [ ] **Data:** Auto-save every 5 minutes
- [ ] **Data:** Recover partial recording on crash
- [ ] **✅ MANUAL TEST:** Kill app during recording → partial file saved

---

## Feature 6: Playback Speed Control
**Deliverable:** Adjust playback speed without pitch distortion
**Depends on:** Feature 4

> **⏳ Status:** Not started

---

### Step 1: Speed UI (Static → Mock)
**Goal:** Speed selector works with mock state

- [ ] **UI:** Add speed button to `PlayerView` (shows "1.0x")
- [ ] **UI:** Speed menu — 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x
- [ ] **ViewModel:** Add `@Published var playbackSpeed: Double = 1.0`
- [ ] **✅ MANUAL TEST:** Speed selector appears, UI updates on selection

---

### Step 2: Real Speed Control (End-to-End)
**Flow:** Select speed → AVAudioUnitTimePitch → Playback changes

- [ ] **Domain:** Extend `AudioPlaybackService` — `setPlaybackSpeed()`, `playbackSpeed`
- [ ] **Data:** Integrate `AVAudioUnitTimePitch` in playback chain
- [ ] **Wire:** Connect ViewModel to service
- [ ] **✅ MANUAL TEST:** Select 2x → audio plays faster without pitch change

---

### Step 3: Persist Preference
**Goal:** Remember user's preferred speed

- [ ] **Domain:** `PlaybackSettingsService` protocol
- [ ] **Data:** `UserDefaultsPlaybackSettingsService`
- [ ] **Wire:** Load saved speed on app launch
- [ ] **✅ MANUAL TEST:** Set speed → kill app → relaunch → speed remembered

---

## Feature 7: Recording Detail View
**Deliverable:** Dedicated screen for single recording
**Depends on:** Feature 3, Feature 4

> **⏳ Status:** Not started

---

### Step 1: Detail UI (Static → Mock)
**Goal:** See detail view with mock data

- [ ] **UI:** Create `RecordingDetailView` — Title, date, duration, file size
- [ ] **UI:** Embed `PlayerView` component
- [ ] **UI:** Action buttons — Edit title, Delete, Share
- [ ] **✅ MANUAL TEST:** Preview in canvas, all elements visible

---

### Step 2: ViewModel & Navigation (End-to-End)
**Flow:** Tap row → RecordingDetailView → Load from repository

- [ ] **ViewModel:** Create `RecordingDetailViewModel` with `@Published var recording`
- [ ] **Wire:** Inject existing use cases (delete, update title, playback)
- [ ] **UI:** Navigate from RecordingsListView → RecordingDetailView
- [ ] **✅ MANUAL TEST:** Tap row → detail opens → edit/delete/play work

---

## Feature 8: Audio Import
**Deliverable:** Import audio files from Files app
**Depends on:** Feature 2

> **⏳ Status:** Not started

---

### Step 1: Import UI (Static → Mock)
**Goal:** File picker works with mock import

- [ ] **UI:** Add import button (+) to RecordingsListView toolbar
- [ ] **UI:** Create `DocumentPickerView` — Filter M4A, MP3, WAV, CAF
- [ ] **UI:** Import progress sheet with progress bar
- [ ] **ViewModel:** Create `ImportViewModel` — `isImporting`, `importProgress`
- [ ] **ViewModel:** Mock `importFile(from:)` with delay
- [ ] **✅ MANUAL TEST:** Tap + → file picker → select → progress → done

---

### Step 2: Real Import (End-to-End)
**Flow:** Select file → ImportAudioUseCase → Copy file → Save to repository

- [ ] **Domain:** `ImportAudioUseCase` — Orchestrates file copy + save
- [ ] **Domain:** `AudioImporterService` protocol
- [ ] **Data:** `FileSystemAudioImporter` — Copy file, read duration metadata
- [ ] **Wire:** Inject use case, replace mock with real import
- [ ] **✅ MANUAL TEST:** Import MP3 from Files → appears in list → plays correctly

---

## Feature 9: Real-Time Transcription (Apple Speech)
**Deliverable:** Live transcription during recording
**Depends on:** Feature 2

> **⏳ Status:** Not started

---

### Step 1: Live Transcript UI (Static → Mock)
**Goal:** See transcript appearing during recording

- [ ] **UI:** Create `LiveTranscriptView` — Text area, "Listening..." indicator, auto-scroll
- [ ] **UI:** Add to RecordingView below record button
- [ ] **ViewModel:** Extend with `liveTranscript`, `isTranscribing`
- [ ] **ViewModel:** Mock text appearing word by word (timer)
- [ ] **✅ MANUAL TEST:** Start recording → text animates in

---

### Step 2: Real Transcription (End-to-End)
**Flow:** Recording audio → SFSpeechRecognizer → Live text updates

- [ ] **Domain:** `Transcript`, `TranscriptSegment`, `TranscriptStatus` entities
- [ ] **Domain:** `SpeechRecognitionService` protocol
- [ ] **Domain:** `StartTranscriptionUseCase`, `SaveDraftTranscriptUseCase`
- [ ] **Data:** `AppleSpeechRecognitionService` — SFSpeechRecognizer, on-device, handle 1-min limit
- [ ] **Wire:** Replace mock with real speech recognition
- [ ] **✅ MANUAL TEST:** Speak → real words appear in transcript

---

### Step 3: Persistence (End-to-End)
**Flow:** Stop recording → Save transcript → Database

- [ ] **Domain:** `TranscriptRepository` protocol
- [ ] **Data:** Transcript + TranscriptSegment tables (migration v2)
- [ ] **Data:** DTOs, Mapper, `SQLiteTranscriptRepository`
- [ ] **✅ MANUAL TEST:** Record → stop → kill app → transcript persists

---

## Feature 10: Transcript Display
**Deliverable:** View transcripts in recording detail
**Depends on:** Feature 9, Feature 7

> **⏳ Status:** Not started

---

### Step 1: Transcript UI (Static → Mock)
**Goal:** See transcript in detail view

- [ ] **UI:** Create `TranscriptView` — Text with timestamps, scrollable
- [ ] **UI:** Add to RecordingDetailView with Player/Transcript toggle
- [ ] **UI:** Add transcript snippet to RecordingRowView (~50 chars)
- [ ] **ViewModel:** Add `transcript` property with mock data
- [ ] **✅ MANUAL TEST:** Detail view shows transcript, list shows preview

---

### Step 2: Real Data (End-to-End)
**Flow:** Open detail → FetchTranscriptUseCase → Load from repository

- [ ] **Domain:** `FetchTranscriptUseCase`
- [ ] **Wire:** Replace mock with repository fetch
- [ ] **✅ MANUAL TEST:** Open recording → real transcript loads

---

## Feature 11: Whisper Integration
**Deliverable:** High-quality background transcription
**Depends on:** Feature 9

> **⏳ Status:** Not started

---

### Step 1: Whisper Processing UI
**Goal:** User sees transcription progress

- [ ] **UI:** Processing indicator on recording row
- [ ] **UI:** Progress percentage display
- [ ] **UI:** Notification when complete, error state with retry
- [ ] **ViewModel:** `TranscriptionQueueViewModel` — queue, progress tracking
- [ ] **✅ MANUAL TEST:** See progress indicator during processing

---

### Step 2: Whisper Service (End-to-End)
**Flow:** Recording → Whisper model → Word-level transcript

- [ ] **Domain:** `TranscriptWord` entity (word, startTime, endTime, confidence)
- [ ] **Domain:** `WhisperTranscriptionService` protocol
- [ ] **Domain:** `ProcessWhisperTranscriptionUseCase`
- [ ] **Data:** Integrate whisper.cpp with Core ML backend
- [ ] **Data:** Whisper Tiny model (75MB) bundled, Base/Small downloadable
- [ ] **Data:** Audio preprocessing — 16kHz mono, chunking for long files
- [ ] **Data:** TranscriptWord table (migration v3)
- [ ] **Wire:** Trigger on recording stop or audio import
- [ ] **✅ MANUAL TEST:** Record → Whisper processes → high-quality transcript appears

---

## Feature 12: Transcript Reconciliation
**Deliverable:** Merge Apple Speech draft with Whisper results
**Depends on:** Feature 11

> **⏳ Status:** Not started

---

### Step 1: Reconciliation (End-to-End)
**Flow:** Draft + Whisper → Merge algorithm → Final transcript

- [ ] **Domain:** `ReconcileTranscriptsUseCase` — Diff/merge, preserve user edits
- [ ] **ViewModel:** Extend with reconciliation logic
- [ ] **UI:** Animate text replacements, show "refining" indicator
- [ ] **UI:** Mark transcript as "final" status
- [ ] **✅ MANUAL TEST:** Draft → Whisper completes → text updates smoothly

---

## Feature 13: Transcript Editor
**Deliverable:** Edit transcript text with undo support
**Depends on:** Feature 10

> **⏳ Status:** Not started

---

### Step 1: Editor UI (Static → Mock)
**Goal:** Tap-to-edit works with undo/redo

- [ ] **UI:** `TranscriptEditorView` — Tap-to-edit, inline editing
- [ ] **UI:** Undo/redo toolbar buttons, shake-to-undo
- [ ] **ViewModel:** `TranscriptEditorViewModel` — edit history, undo stack
- [ ] **✅ MANUAL TEST:** Edit text → undo → redo works

---

### Step 2: Real Editing (End-to-End)
**Flow:** Edit segment → UpdateUseCase → Repository → Pinned for reconciliation

- [ ] **Domain:** Extend `TranscriptSegment` — `isEdited`, `isPinned`
- [ ] **Domain:** `UpdateTranscriptSegmentUseCase`, `PinTranscriptSegmentUseCase`
- [ ] **Data:** Migration v4 — add isEdited, isPinned columns
- [ ] **Wire:** Edited segments marked as pinned (preserved in reconciliation)
- [ ] **✅ MANUAL TEST:** Edit → save → Whisper runs → edit preserved

---

## Feature 14: Full-Text Search
**Deliverable:** Search across all transcripts
**Depends on:** Feature 10

> **⏳ Status:** Not started

---

### Step 1: Search UI (Static → Mock)
**Goal:** Search bar works with mock results

- [ ] **UI:** Update `SearchView` with search bar, empty state
- [ ] **UI:** `SearchResultRow` — Title, highlighted snippet, timestamp
- [ ] **ViewModel:** `SearchViewModel` — query, results, isSearching
- [ ] **ViewModel:** Mock search with filtered data
- [ ] **✅ MANUAL TEST:** Type query → mock results appear

---

### Step 2: Real Search (End-to-End)
**Flow:** Query → FTS5 index → Results → Navigate to match

- [ ] **Domain:** `SearchResult` entity, `SearchTranscriptsUseCase`
- [ ] **Data:** FTS5 virtual table (migration v5)
- [ ] **Data:** `SQLiteSearchService` — phrase search, prefix search
- [ ] **Wire:** Populate index on transcript save
- [ ] **UI:** Tap result → detail view scrolled to match
- [ ] **✅ MANUAL TEST:** Search "meeting" → finds all transcripts with "meeting"

---

## Feature 15: Playback-Transcript Sync
**Deliverable:** Words highlight as audio plays
**Depends on:** Feature 11, Feature 4

> **⏳ Status:** Not started

---

### Step 1: Sync UI (Mock)
**Goal:** Highlight moves through transcript

- [ ] **UI:** Highlight current word/sentence in TranscriptView
- [ ] **UI:** Auto-scroll to follow playback (interrupt on user scroll)
- [ ] **UI:** Tap word → seek audio to that timestamp
- [ ] **ViewModel:** Add `currentWord`, `currentSegment` to PlaybackViewModel
- [ ] **ViewModel:** Mock highlight moving through text
- [ ] **✅ MANUAL TEST:** Play → highlight moves → tap word → audio seeks

---

### Step 2: Real Sync (End-to-End)
**Flow:** Playback time → Timestamp index → Current word

- [ ] **Domain:** `PlaybackSyncService` protocol, `SyncPlaybackToTranscriptUseCase`
- [ ] **Data:** `TimestampIndexService` — timestamp ↔ word lookup
- [ ] **Wire:** 60fps updates from playback to highlight
- [ ] **✅ MANUAL TEST:** Play recording → words highlight in sync with audio

---

## Feature 16: Folders
**Deliverable:** Organize recordings into folders
**Depends on:** Feature 3

> **⏳ Status:** Not started

---

### Step 1: Folder UI (Static → Mock)
**Goal:** See folder navigation and organization

- [ ] **UI:** Folder sidebar/navigation
- [ ] **UI:** Folder indicator in RecordingRowView
- [ ] **UI:** Drag-and-drop recordings to folders
- [ ] **ViewModel:** `FoldersViewModel` — folders list, mock data
- [ ] **✅ MANUAL TEST:** Create folder → drag recording → see in folder

---

### Step 2: Real Folders (End-to-End)
**Flow:** Create folder → Move recording → Persist

- [ ] **Domain:** `Folder` entity, extend `Recording` with `folderID`
- [ ] **Domain:** `FolderRepository` protocol
- [ ] **Domain:** `CreateFolderUseCase`, `MoveRecordingToFolderUseCase`
- [ ] **Data:** Folder table + Recording.folderID (migration v6)
- [ ] **Data:** `FolderDTO`, `FolderMapper`, `SQLiteFolderRepository`
- [ ] **✅ MANUAL TEST:** Create folder → move recording → kill app → folder persists

---

## Feature 17: Tags
**Deliverable:** Tag recordings for filtering
**Depends on:** Feature 3

> **⏳ Status:** Not started

---

### Step 1: Tag UI (Static → Mock)
**Goal:** Create and assign color-coded tags

- [ ] **UI:** Tag chips in RecordingRowView (color-coded)
- [ ] **UI:** Tag filter in recordings list toolbar
- [ ] **UI:** Assign tags UI in detail/context menu
- [ ] **ViewModel:** `TagsViewModel` — tags list, mock data
- [ ] **✅ MANUAL TEST:** Create tag → assign to recording → filter by tag

---

### Step 2: Real Tags (End-to-End)
**Flow:** Create tag → Assign to recording → Filter → Persist

- [ ] **Domain:** `Tag` entity, `RecordingTag` junction
- [ ] **Domain:** `TagRepository` protocol
- [ ] **Domain:** `CreateTagUseCase`, `AssignTagToRecordingUseCase`, `FilterRecordingsByTagUseCase`
- [ ] **Data:** Tag + RecordingTag tables (migration v7)
- [ ] **Data:** `TagDTO`, `TagMapper`, `SQLiteTagRepository`
- [ ] **✅ MANUAL TEST:** Create tag → assign → filter → kill app → tags persist

---

## Feature 18: Speaker Diarization
**Deliverable:** Identify different speakers in recordings
**Depends on:** Feature 11

> **⏳ Status:** Not started

---

### Step 1: Speaker UI (Static → Mock)
**Goal:** See speaker labels in transcript

- [ ] **UI:** Speaker avatar (initials, color) in transcript margin
- [ ] **UI:** Speaker label tap to rename
- [ ] **UI:** Speaker filter, speaker list with statistics
- [ ] **UI:** Reassign segment, merge speakers
- [ ] **ViewModel:** `SpeakersViewModel` — mock speakers
- [ ] **✅ MANUAL TEST:** See color-coded speakers in transcript

---

### Step 2: Real Diarization (End-to-End)
**Flow:** Audio → Speaker embedding → Clustering → Speaker assignments

- [ ] **Domain:** `Speaker` entity, `SpeakerRepository` protocol
- [ ] **Domain:** `SpeakerDiarizationService` protocol
- [ ] **Domain:** `ProcessDiarizationUseCase`
- [ ] **Data:** Speaker table + TranscriptSegment.speakerID (migration v8)
- [ ] **Data:** Speaker encoder model (~15MB Core ML)
- [ ] **Data:** `SpeakerEmbeddingService` — 1.5s windows, embeddings
- [ ] **Data:** HDBSCAN clustering with cosine similarity
- [ ] **Wire:** Run diarization after Whisper
- [ ] **✅ MANUAL TEST:** Record conversation → speakers auto-identified

---

## Feature 19: On-Device LLM Integration
**Deliverable:** Local LLM for AI features
**Depends on:** Feature 10

> **⏳ Status:** Not started

---

### Step 1: LLM Infrastructure (End-to-End)
**Flow:** Model download → Load → Generate text

- [ ] **Domain:** `LLMService` protocol — `generate()`, `isAvailable`
- [ ] **Data:** Integrate llama.cpp or mlc-llm
- [ ] **Data:** Phi-3-mini or Llama 3.2 3B (4-bit quantized, ~2.2GB)
- [ ] **Data:** Model downloader with progress, store in App Support
- [ ] **UI:** Model selection in Settings, memory warnings
- [ ] **✅ MANUAL TEST:** Download model → generate text response

---

## Feature 20: Summarization
**Deliverable:** AI-generated summaries of recordings
**Depends on:** Feature 19

> **⏳ Status:** Not started

---

### Step 1: Summary UI (Static → Mock)
**Goal:** See summary in detail view

- [ ] **UI:** Summary section in RecordingDetailView
- [ ] **UI:** "Generate Summary" button, progress indicator
- [ ] **ViewModel:** Add `summary`, `isGeneratingSummary`
- [ ] **ViewModel:** Mock summary generation with delay
- [ ] **✅ MANUAL TEST:** Tap generate → progress → summary appears

---

### Step 2: Real Summarization (End-to-End)
**Flow:** Transcript → LLM → Brief/detailed summary

- [ ] **Domain:** Extend `Transcript` with `summary`
- [ ] **Domain:** `GenerateSummaryUseCase` — brief, detailed, action items
- [ ] **Data:** Migration v9 — add summary column
- [ ] **Data:** Fallback TextRank for low memory devices
- [ ] **Wire:** Handle long transcripts (chunking + map-reduce)
- [ ] **✅ MANUAL TEST:** Generate summary → cached for future views

---

## Feature 21: Export
**Deliverable:** Export transcripts in multiple formats
**Depends on:** Feature 13

> **⏳ Status:** Not started

---

### Step 1: Export UI (Static → Mock)
**Goal:** Export options sheet works

- [ ] **UI:** Export options sheet — format selection, include options
- [ ] **UI:** Preview, progress indicator
- [ ] **UI:** Share via UIActivityViewController, AirDrop, clipboard
- [ ] **ViewModel:** `ExportViewModel` — options, isExporting, progress
- [ ] **✅ MANUAL TEST:** Tap export → select format → share sheet appears

---

### Step 2: Real Export (End-to-End)
**Flow:** Recording → ExportService → File → Share

- [ ] **Domain:** `ExportFormat` enum (txt, md, json, docx, pdf, srt, vtt)
- [ ] **Domain:** `ExportOptions`, `ExportRecordingUseCase`
- [ ] **Data:** `ExportServiceImpl` — all format generators
- [ ] **✅ MANUAL TEST:** Export to each format → opens correctly in target app

---

## Feature 22: iOS System Integration
**Deliverable:** Integrate with iOS system features
**Depends on:** Feature 2, Feature 4

> **⏳ Status:** Not started

---

### Step 1: Siri Shortcuts
- [ ] App Intents: Start Recording, Stop Recording, Search Transcripts
- [ ] Donate intents for Siri suggestions
- [ ] **✅ MANUAL TEST:** "Hey Siri, start recording in AudioBuddy"

### Step 2: Home Screen Widgets
- [ ] Widget extension target
- [ ] Small: Quick record button
- [ ] Medium: Recent recordings + record
- [ ] Deep linking from widgets
- [ ] **✅ MANUAL TEST:** Add widget → tap → app opens correctly

### Step 3: Spotlight Integration
- [ ] Index recordings and transcript content
- [ ] Deep link from Spotlight results
- [ ] **✅ MANUAL TEST:** Search in Spotlight → find recording → tap → opens

### Step 4: Calendar Integration
- [ ] Extend `Recording` with `calendarEventID` (migration v10)
- [ ] Auto-title from current calendar event
- [ ] **✅ MANUAL TEST:** Start recording during meeting → auto-titled

---

## Feature 23: Performance & Polish
**Deliverable:** Fast, efficient, accessible app
**Depends on:** All previous features

> **⏳ Status:** Not started

---

### Step 1: Performance
- [ ] Profile CPU/memory, fix leaks
- [ ] Optimize Whisper and LLM inference
- [ ] Reduce app launch time
- [ ] Low Power Mode, defer ML to charging
- [ ] **✅ MANUAL TEST:** No lag, smooth animations

### Step 2: Accessibility
- [ ] VoiceOver, Dynamic Type, High Contrast
- [ ] Reduce Motion support
- [ ] Accessibility labels and hints
- [ ] **✅ MANUAL TEST:** Full VoiceOver navigation works

### Step 3: Localization
- [ ] Extract strings, localization infrastructure
- [ ] Translate to target languages
- [ ] **✅ MANUAL TEST:** Change language → app fully localized

### Step 4: Error Handling & Onboarding
- [ ] Comprehensive error handling, storage full
- [ ] First launch tutorial, permission flow
- [ ] **✅ MANUAL TEST:** Fresh install → smooth onboarding

---

## Database Schema Evolution

| Feature | Migration | Tables/Columns Added |
|---------|-----------|---------------------|
| 2 | v1 | Recording |
| 9 | v2 | Transcript, TranscriptSegment |
| 11 | v3 | TranscriptWord |
| 13 | v4 | TranscriptSegment.isEdited, isPinned |
| 14 | v5 | transcripts_fts (FTS5) |
| 16 | v6 | Folder, Recording.folderID |
| 17 | v7 | Tag, RecordingTag |
| 18 | v8 | Speaker, TranscriptSegment.speakerID |
| 20 | v9 | Transcript.summary |
| 22 | v10 | Recording.calendarEventID |

---

## Feature Dependencies Graph

```
Feature 1 (Foundation)
    │
    └── Feature 2 (Audio Recording - Complete Slice)
            │
            ├── Feature 3 (Recordings List - Complete Slice)
            │       │
            │       ├── Feature 7 (Detail View)
            │       ├── Feature 16 (Folders)
            │       └── Feature 17 (Tags)
            │
            ├── Feature 4 (Audio Playback - Complete Slice)
            │       │
            │       ├── Feature 6 (Speed Control)
            │       └── Feature 15 (Playback-Transcript Sync)
            │
            ├── Feature 5 (Background Recording)
            │
            ├── Feature 8 (Audio Import)
            │
            └── Feature 9 (Real-Time Transcription - Complete Slice)
                    │
                    ├── Feature 10 (Transcript Display)
                    │       │
                    │       ├── Feature 13 (Transcript Editor)
                    │       │       └── Feature 14 (Full-Text Search)
                    │       │
                    │       └── Feature 15 (Playback-Transcript Sync)
                    │
                    └── Feature 11 (Whisper Integration - Complete Slice)
                            │
                            ├── Feature 12 (Transcript Reconciliation)
                            │
                            └── Feature 18 (Speaker Diarization - Complete Slice)
                                    │
                                    └── Feature 19 (LLM Integration - Complete Slice)
                                            │
                                            └── Feature 20 (Summarization - Complete Slice)
                                                    │
                                                    └── Feature 21 (Export - Complete Slice)
                                                            │
                                                            └── Feature 22 (iOS Integration)
                                                                    │
                                                                    └── Feature 23 (Performance & Polish)
```

---

## Shippable Milestones

| Milestone | Features | User Value |
|-----------|----------|------------|
| MVP Recorder | 1-3 | Basic voice recorder with persistence |
| + Playback | 4, 6, 7 | Full record & playback experience |
| + Import | 8 | Process external audio |
| + Live Transcription | 9-10 | Real-time speech-to-text |
| + Whisper | 11-12 | High-accuracy transcription |
| + Editor | 13-14 | Professional transcript editing |
| + Sync | 15 | Audio-transcript synchronization |
| + Organization | 16-17 | Folders & tags |
| + Speakers | 18 | Multi-speaker identification |
| + AI | 19-20 | Summaries & insights |
| + Export | 21 | Share anywhere |
| + iOS Integration | 22 | System-level features |
| + Polish | 23 | Production ready |

---

## Development Principles

### UI-First Vertical Slicing
1. **UI First**: Start with Views using mock data → see it working immediately
2. **End-to-End Steps**: Each step delivers complete functionality (UI → Domain → Data)
3. **Manual Test After Each Step**: Verify before proceeding
4. **No Unused Infrastructure**: Build only what the current step needs

### Clean Architecture
1. **Dependency Rule**: Presentation → Domain ← Data (dependencies point inward)
2. **Domain Independence**: No framework dependencies in Domain layer
3. **Swappable Implementations**: Mock → Real without changing interfaces

### Implementation Flow
```
1. UI (Static)     → Preview in canvas
2. ViewModel (Mock) → Tap buttons, see state changes
3. Domain          → Entities, protocols, use cases
4. Data            → Services, repositories, mappers
5. Wire            → Replace mocks with real implementations
6. Manual Test E2E → Complete flow works
```

### Testing Checkpoints
- ✅ Run app after each step
- ✅ Test on real device for audio
- ✅ Test edge cases: empty states, errors, permissions denied
- ✅ Test persistence: kill app → relaunch → data survives

---

*Last Updated: December 28, 2025*
