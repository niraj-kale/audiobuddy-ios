# Audio Buddy iOS

A privacy-focused audio recording app for iOS. Records all audio locally with no cloud connection.

## Features

- **Private Recording**: All audio recordings are stored locally on your device
- **No Cloud Connection**: Your recordings never leave your device - no uploads, no syncing, no cloud storage
- **Simple Interface**: Easy-to-use recording controls with a clean, modern SwiftUI interface
- **Playback Controls**: Listen to your recordings with play/pause, seek, and skip controls
- **Recording Management**: View, play, and delete your recordings

## Privacy

Audio Buddy is designed with privacy as the primary concern:

- All recordings are stored in the app's local Documents directory
- No network requests are made by the app
- No analytics or tracking
- No third-party services or SDKs
- Microphone access is only used for recording when you explicitly tap the record button

## Requirements

- iOS 17.0 or later
- iPhone or iPad

## Installation

1. Clone the repository
2. Open `AudioBuddy/AudioBuddy.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build and run

## Usage

### Recording
1. Open the app and ensure microphone permission is granted
2. Tap the red record button to start recording
3. Tap the stop button (square) to stop and save the recording
4. Optionally tap "Cancel Recording" to discard without saving

### Playback
1. Navigate to the "Recordings" tab
2. Tap on any recording to open the playback view
3. Use play/pause, skip forward/backward controls
4. Use the slider to seek to any position

### Managing Recordings
1. In the Recordings list, swipe left on any recording to delete
2. Tap "Edit" to enter edit mode for bulk deletion

## Project Structure

```
AudioBuddy/
├── AudioBuddy/
│   ├── AudioBuddyApp.swift       # App entry point
│   ├── ContentView.swift         # Main tab view
│   ├── Models/
│   │   └── Recording.swift       # Recording data model
│   ├── Managers/
│   │   ├── AudioRecorderManager.swift   # Handles recording
│   │   ├── AudioPlayerManager.swift     # Handles playback
│   │   └── RecordingsManager.swift      # Manages saved recordings
│   └── Views/
│       ├── RecordingView.swift          # Recording UI
│       ├── RecordingsListView.swift     # List of recordings
│       └── AudioPlayerView.swift        # Playback UI
├── AudioBuddyTests/
│   └── AudioBuddyTests.swift     # Unit tests
└── AudioBuddyUITests/
    ├── AudioBuddyUITests.swift   # UI tests
    └── AudioBuddyUITestsLaunchTests.swift
```

## License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE](LICENSE) file for details.