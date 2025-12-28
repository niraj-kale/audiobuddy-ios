# Features Specification — On-Device Transcription App

## Table of Contents

1. [Core Transcription Engine](#1-core-transcription-engine)
2. [Speaker Diarization](#2-speaker-diarization)
3. [Audio Recording & Playback](#3-audio-recording--playback)
4. [AI Processing](#4-ai-processing)
5. [Search & Organization](#5-search--organization)
6. [Editor](#6-editor)
7. [Export & Sharing](#7-export--sharing)
8. [iOS System Integration](#8-ios-system-integration)
9. [Privacy & Data Architecture](#9-privacy--data-architecture)

---

## 1. Core Transcription Engine

### 1.1 Hybrid Dual-Pass Architecture

The transcription system operates in two concurrent phases to balance latency against accuracy.

**Pass 1 — Real-Time Draft (Apple Speech Framework)**

| Aspect | Detail |
|--------|--------|
| Engine | `SFSpeechRecognizer` with `requiresOnDeviceRecognition = true` |
| Latency | ~200-500ms from utterance to text |
| Granularity | Partial results streamed at word boundaries |
| Limitations | 1-minute recognition tasks; app manages segment boundaries transparently |
| Purpose | Immediate user feedback during recording |

**Pass 2 — Background Refinement (Whisper.cpp)**

| Aspect | Detail |
|--------|--------|
| Engine | whisper.cpp with Core ML backend (Apple Neural Engine) |
| Models | User-selectable: tiny (fast, ~75MB), base (balanced, ~150MB), small (accurate, ~500MB) |
| Trigger | Automatic on recording stop; optional periodic refinement every N minutes for long sessions |
| Behavior | Replaces draft transcript segment-by-segment; preserves user edits made to draft |
| Word Timestamps | Whisper provides word-level timing; used for playback sync |

**Transcript Reconciliation**

When Whisper results arrive:
1. Diff against draft transcript at word-alignment level
2. Preserve any user corrections (edits marked as "pinned")
3. Animate text replacements in UI to avoid jarring jumps
4. Update word-timestamp index for playback sync

### 1.2 Supported Languages

On-device recognition constrains language support. Initial release:

| Language | Apple Speech | Whisper | Notes |
|----------|--------------|---------|-------|
| English (US/UK/AU) | ✓ | ✓ | Full support |
| Spanish | ✓ | ✓ | Full support |
| French | ✓ | ✓ | Full support |
| German | ✓ | ✓ | Full support |
| Japanese | ✓ | ✓ | Whisper only for refinement |
| Mandarin | ✓ | ✓ | Whisper only for refinement |

Language auto-detection via initial 10-second sample analyzed by Whisper's language identification head.

### 1.3 Audio Preprocessing

Before recognition:

| Stage | Implementation | Purpose |
|-------|----------------|---------|
| Noise Gate | vDSP threshold filter | Eliminate low-level background hum |
| Voice Activity Detection | Energy + zero-crossing rate | Skip silence, segment on pauses |
| Normalization | Peak normalization to -3dB | Consistent input levels across devices/environments |
| Resampling | 16kHz mono | Whisper's expected input format |

Preprocessing runs on dedicated audio processing queue; adds ~10ms latency.

---

## 2. Speaker Diarization

### 2.1 Pipeline Overview

Speaker identification runs as a post-processing step after Whisper refinement completes.

```
[Audio Segments] → [Embedding Extraction] → [Clustering] → [Label Assignment]
```

### 2.2 Embedding Extraction

| Component | Detail |
|-----------|--------|
| Model | ResNet-based speaker encoder (~15MB), Core ML optimized |
| Input | 1.5-second audio windows, 0.75s hop |
| Output | 256-dimensional speaker embedding per window |
| Source | Derived from SpeechBrain/Resemblyzer architecture |

### 2.3 Clustering Algorithm

| Approach | HDBSCAN (primary) / Agglomerative (fallback) |
|----------|----------------------------------------------|
| Distance Metric | Cosine similarity on embeddings |
| Min Cluster Size | 3 segments (prevents single-utterance "speakers") |
| Unknown Handling | Segments below confidence threshold marked "Unknown Speaker" |

### 2.4 Speaker Profiles

Users can create persistent speaker profiles for recognition across recordings.

| Feature | Behavior |
|---------|----------|
| Enrollment | 30 seconds of isolated speech from target speaker |
| Storage | Averaged embedding stored in local profile database |
| Matching | New recordings compared against profile embeddings; auto-labeled if similarity > 0.85 |
| Correction | User relabels segment → profile embedding updated incrementally |

### 2.5 UI Representation

- Each speaker assigned consistent color throughout transcript
- Speaker avatar (initials or photo if linked to contact) in left margin
- Tap speaker label to rename; propagates to all segments from that speaker
- Filter view: show only segments from selected speaker(s)

---

## 3. Audio Recording & Playback

### 3.1 Recording

**Audio Capture Pipeline**

```
[Microphone] → AVAudioEngine Input Node → [Tap]
                                             ├── Ring Buffer (Speech Framework)
                                             └── File Writer (WAV/M4A)
```

| Parameter | Value |
|-----------|-------|
| Sample Rate | 48kHz capture, downsampled to 16kHz for ML |
| Bit Depth | 16-bit PCM |
| Channels | Mono (stereo mixed down) |
| Format (storage) | AAC in M4A container (configurable) |
| Max Duration | Limited by storage; tested to 8+ hours |

**Input Sources**

| Source | Implementation |
|--------|----------------|
| Built-in Microphone | Default AVAudioSession |
| AirPods / Bluetooth | Automatic routing via AVAudioSession |
| External USB Mic | Supported on iPad; requires Camera Connection Kit |
| Wired Headset | Standard iOS routing |

**Background Recording**

- `AVAudioSession` category: `.playAndRecord` with `.allowBluetooth` and `.defaultToSpeaker`
- Background mode: `audio` capability enabled
- Recording continues when app backgrounded; system may interrupt for calls
- Battery optimization: reduce Whisper processing frequency in background

### 3.2 Playback

| Feature | Implementation |
|---------|----------------|
| Engine | AVAudioPlayer / AVAudioEngine for advanced features |
| Speed Control | 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x (AVAudioUnitTimePitch) |
| Skip Silence | VAD-detected silent regions auto-skipped; ~30% time savings typical |
| Word Sync | Current word highlighted; transcript auto-scrolls |
| Tap-to-Seek | Tap any word → playback jumps to that timestamp |
| Scrubbing | Drag playhead; nearest word highlighted during scrub |

### 3.3 Audio Import

| Source | Method |
|--------|--------|
| Files App | Document picker; supports M4A, MP3, WAV, CAF, MP4 (audio extracted) |
| Share Sheet | Receive audio/video from other apps |
| Voice Memos | Via Files or share sheet |
| Drag & Drop | iPad multitasking |

Import triggers Whisper transcription (no real-time pass needed).

---

## 4. AI Processing

All AI features run entirely on-device. No network calls.

### 4.1 Summarization

**Engine:** Local LLM — Phi-3-mini (3.8B parameters) or Llama 3.2 3B, quantized to 4-bit via llama.cpp/mlc-llm.

| Summary Type | Prompt Strategy | Output |
|--------------|-----------------|--------|
| Brief | "Summarize in 2-3 sentences" | Quick overview |
| Detailed | "Summarize with key points and decisions" | Structured summary with bullets |
| Action Items | "Extract action items with owners if mentioned" | Checklist format |
| Custom | User-defined prompt template | Flexible |

**Constraints:**
- Context window: ~4K tokens typical; long transcripts chunked with map-reduce summarization
- Latency: 10-30 seconds depending on transcript length and device (M-series iPad fastest)
- Memory: ~3GB RAM required; graceful fallback to extractive summarization on older devices

**Fallback — Extractive Summarization:**

For devices without sufficient RAM or when speed is critical:
- TextRank implementation via NaturalLanguage framework
- Sentence scoring based on TF-IDF and position
- Top N sentences extracted, preserving order
- No hallucination risk; lower quality than abstractive

### 4.2 Keyword & Topic Extraction

| Method | Detail |
|--------|--------|
| Primary | LLM-based extraction ("List 5-10 key topics") |
| Fallback | NaturalLanguage framework's `NLTagger` with `.nameType`, `.organizationName`, `.placeName` |
| Frequency | TF-IDF weighted term frequency across transcript |
| Output | Tags attached to recording; used for search and smart folders |

### 4.3 Transcript Q&A

User can query the transcript in natural language.

| Example Query | Behavior |
|---------------|----------|
| "What did John say about the budget?" | Filter to John's segments, summarize budget-related content |
| "When is the deadline?" | Extract temporal references, return with timestamps |
| "List all mentioned names" | NER extraction + LLM refinement |

**Implementation:**
1. Query analyzed for intent (search vs. summarize vs. extract)
2. Relevant transcript segments retrieved via embedding similarity or keyword match
3. LLM generates response grounded in retrieved segments
4. Citations link back to specific transcript timestamps

### 4.4 Follow-up Generation

Generate contextual follow-ups from meeting content:

| Output Type | Example |
|-------------|---------|
| Email Draft | "Draft a follow-up email summarizing decisions" |
| Task List | "Create tasks from this meeting" |
| Meeting Notes | "Format as shareable meeting notes" |

User can edit generated content before export.

---

## 5. Search & Organization

### 5.1 Full-Text Search

**Engine:** SQLite FTS5 with porter tokenizer

| Capability | Detail |
|------------|--------|
| Instant Search | Indexed on transcript save; sub-100ms query response |
| Phrase Search | Quoted strings match exact sequence |
| Boolean | AND, OR, NOT operators |
| Prefix | "meet*" matches "meeting", "meetings" |
| Highlighting | Matching terms highlighted in results |
| Snippet | Context around match displayed in search results |

Search scope: across all recordings or within single recording.

### 5.2 Organization

**Folders**
- User-created hierarchical folders
- Drag-and-drop organization
- Smart Folders: dynamic based on criteria (date range, keywords, speakers, duration)

**Tags**
- Manual tags applied by user
- Auto-tags from keyword extraction
- Tag-based filtering in list view

**Metadata**
- Title (auto-generated from first sentence or calendar event; editable)
- Date/time recorded
- Duration
- Location (optional; from Core Location if permitted)
- Linked calendar event

### 5.3 Timeline View

Chronological view of all recordings with:
- Day/week/month grouping
- Visual duration indicator
- Quick preview on long-press
- Calendar integration overlay

---

## 6. Editor

### 6.1 Text Editing

| Feature | Behavior |
|---------|----------|
| Direct Edit | Tap text to edit; corrects transcription errors |
| Edit Pinning | Edited regions marked; preserved across Whisper re-processing |
| Undo/Redo | Full edit history per session |
| Find & Replace | Within single transcript |

### 6.2 Speaker Correction

- Tap speaker label to reassign segment to different speaker
- Merge speakers: combine two speaker identities that are actually the same person
- Split speaker: divide incorrectly merged speaker

### 6.3 Highlights & Annotations

| Feature | Detail |
|---------|--------|
| Highlight | Select text → apply color highlight (5 colors available) |
| Comment | Attach note to highlighted region |
| Bookmark | Mark important moments; appears in navigation sidebar |
| Star | Flag entire recording as important |

### 6.4 Paragraph & Formatting

- Auto-paragraphing based on speaker changes and pauses
- Manual paragraph breaks (insert/remove)
- Timestamps shown inline (toggleable)
- Reading mode: hide timestamps and speaker labels for cleaner reading

---

## 7. Export & Sharing

### 7.1 Export Formats

| Format | Content | Use Case |
|--------|---------|----------|
| Plain Text (.txt) | Transcript only | Universal compatibility |
| Markdown (.md) | Transcript with speaker labels, timestamps, highlights | Note-taking apps |
| Word (.docx) | Formatted transcript | Business/professional |
| PDF | Formatted transcript | Archival, printing |
| SRT/VTT | Subtitles with timing | Video editing |
| JSON | Full structured data (transcript, speakers, timestamps, metadata) | Developer/automation |
| Audio (M4A/MP3) | Original recording | Archival, re-processing |

### 7.2 Bulk Export

- Select multiple recordings → export as ZIP
- Maintains folder structure
- Background export with progress notification

### 7.3 Sharing

| Method | Implementation |
|--------|----------------|
| Share Sheet | Standard iOS share with format selection |
| AirDrop | Direct device-to-device |
| Copy to Clipboard | Text or Markdown |
| Files Integration | Save to iCloud Drive, local storage, third-party providers |

### 7.4 Collaboration (Local Network)

Optional feature for team scenarios without cloud:

- Bonjour service discovery on local network
- Send recording + transcript to another device running the app
- Recipient can view, not edit (or full copy)
- No server required; peer-to-peer transfer

---

## 8. iOS System Integration

### 8.1 Siri Shortcuts

| Shortcut | Action |
|----------|--------|
| "Start Recording" | Launch app, begin recording immediately |
| "Stop Recording" | End current recording, begin processing |
| "Transcribe Last Voice Memo" | Import most recent Voice Memo, transcribe |
| "Search Transcripts" | Open app to search with optional query parameter |

Shortcuts support Automations (e.g., start recording when joining calendar event).

### 8.2 Widgets

**Home Screen Widgets**

| Size | Content |
|------|---------|
| Small | Quick-record button |
| Medium | Recent recordings list (3 items) + record button |
| Large | Recent recordings + search + record |

**Lock Screen Widget**
- Record button (iOS 16+)

**Control Center**
- Quick-record toggle (custom control, iOS 18+)

### 8.3 Calendar Integration

| Feature | Behavior |
|---------|----------|
| Event Sync | Upcoming events displayed; tap to pre-title recording |
| Auto-Title | Recording started during calendar event auto-titled with event name |
| Event Linking | Recording linked to calendar event; accessible from event details |

### 8.4 Contacts Integration

- Speaker profiles can link to Contacts
- Contact photo used as speaker avatar
- Suggested speaker matches based on meeting attendees (from calendar event)

### 8.5 Files App Integration

- App folder visible in Files
- Recordings accessible as audio files
- Transcripts accessible as text/markdown

### 8.6 Handoff & Continuity

- Start recording on iPhone, continue on iPad (if both on same network)
- Transcript editing state preserved across handoff
- Requires local sync mechanism (no cloud)

### 8.7 Focus Modes

- Recording activity signals "Do Not Disturb for Recording" suggestion
- Optional: auto-enable Focus when recording starts

---

## 9. Privacy & Data Architecture

### 9.1 Core Privacy Principles

| Principle | Implementation |
|-----------|----------------|
| No Cloud | Zero network transmission of audio or transcripts |
| On-Device ML | All models run locally; no API calls |
| User Ownership | All data stored in app sandbox and user-accessible via Files |
| No Tracking | No analytics SDKs; optional anonymous crash reporting only |

### 9.2 Data Storage

**Database:** SQLite with SQLCipher encryption (AES-256)

| Data | Storage |
|------|---------|
| Transcripts | SQLite FTS5 table, encrypted at rest |
| Metadata | SQLite tables |
| Audio Files | App Documents directory, iOS Data Protection (Complete) |
| ML Models | App bundle (shipped) or App Support (downloaded) |
| Speaker Profiles | SQLite, encrypted |

**Encryption Key:** Derived from device passcode via iOS Keychain; data inaccessible without device unlock.

### 9.3 Backup & Sync

| Method | Behavior |
|--------|----------|
| iCloud Backup | Included by default (user can exclude in iOS Settings) |
| Local Backup | Via Finder/iTunes; encrypted if backup encryption enabled |
| Manual Export | User-initiated export to Files for personal backup |
| iCloud Drive Sync | Optional; user-controlled folder sync |

**No proprietary cloud sync.** Users wanting sync use iCloud Drive or third-party file sync.

### 9.4 Permissions

| Permission | Usage | Required |
|------------|-------|----------|
| Microphone | Audio recording | Yes (core function) |
| Speech Recognition | Apple real-time transcription | Yes (core function) |
| Calendar | Event integration, auto-titling | Optional |
| Contacts | Speaker profile linking | Optional |
| Location | Geotagging recordings | Optional |

### 9.5 Data Deletion

| Action | Behavior |
|--------|----------|
| Delete Recording | Audio file + transcript + metadata removed; SQLite VACUUM |
| Delete Speaker Profile | Profile removed; historical labels preserved as text |
| Delete All Data | Full database wipe; reset to fresh install |
| Account-Free | No account system; nothing to "delete account" |

### 9.6 Security Considerations

| Threat | Mitigation |
|--------|------------|
| Device Theft | iOS Data Protection; encrypted database; requires passcode |
| Memory Dump | Sensitive audio buffers cleared after processing |
| Model Extraction | Models are public (Whisper); no proprietary IP in model files |
| Malicious Audio | Input validation; no code execution paths from audio content |

---

## Appendix A: Model Sizes & Performance

| Model | Size | Transcription Speed (iPhone 15 Pro) | Accuracy (WER) |
|-------|------|-------------------------------------|----------------|
| Whisper Tiny | 75 MB | ~10x real-time | ~12% |
| Whisper Base | 150 MB | ~6x real-time | ~9% |
| Whisper Small | 500 MB | ~3x real-time | ~6% |
| Speaker Encoder | 15 MB | <100ms per segment | N/A |
| Phi-3-mini (4-bit) | 2.2 GB | ~15 tokens/sec | N/A |

---

## Appendix B: Storage Estimates

| Content | Size per Hour |
|---------|---------------|
| Audio (AAC 64kbps) | ~28 MB |
| Transcript (text) | ~100 KB |
| Timestamps + metadata | ~200 KB |
| Speaker embeddings | ~500 KB |
| **Total per hour** | **~30 MB** |

1000 hours of recordings ≈ 30 GB

---

## Appendix C: Battery Impact

| Activity | Impact |
|----------|--------|
| Recording only | Minimal (~5% per hour) |
| Recording + Apple real-time | Moderate (~10% per hour) |
| Whisper processing | High (~20% for 1 hour audio, completes in ~20 min) |
| LLM summarization | High (~5% per summary, completes in ~30 sec) |

Recommendations:
- Process Whisper while plugged in when possible
- Offer "Low Power Mode" that defers all ML to later