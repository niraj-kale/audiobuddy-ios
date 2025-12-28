import SwiftUI

struct RecordingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: RecordingViewModel
    @State private var showDiscardAlert = false
    
    init(viewModel: RecordingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Permission Banner
            if viewModel.permissionDenied {
                permissionBanner
            }
            
            // Error Message
            if let error = viewModel.errorMessage {
                errorBanner(error)
            }
            
            // Duration Timer
            timerDisplay
            
            // Record Button
            recordButton
            
            // Control Buttons (Pause/Save/Discard)
            if viewModel.state != .idle {
                controlButtons
            }
            
            Spacer()
        }
        .padding()
        .alert("Discard Recording?", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive) {
                viewModel.discardRecording()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This recording will be permanently deleted.")
        }
        .onAppear {
            viewModel.onRecordingSaved = {
                dismiss()
            }
        }
    }
    
    // MARK: - Permission Banner
    private var permissionBanner: some View {
        HStack {
            Image(systemName: "mic.slash.fill")
                .foregroundColor(.orange)
            Text("Microphone access required")
                .font(Theme.Typography.caption)
            Spacer()
            Button("Settings") {
                openSettings()
            }
            .font(Theme.Typography.caption)
            .foregroundColor(Theme.primaryColor)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Error Banner
    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(Theme.Typography.caption)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Timer Display
    private var timerDisplay: some View {
        Text(viewModel.formattedDuration)
            .font(.system(size: 72, weight: .thin, design: .monospaced))
            .foregroundColor(viewModel.isRecording ? .red : Theme.secondaryColor)
            .contentTransition(.numericText())
            .animation(.default, value: viewModel.duration)
    }
    
    // MARK: - Record Button
    private var recordButton: some View {
        Button {
            handleRecordTap()
        } label: {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(viewModel.state != .idle ? Color.red : Color.red.opacity(0.3), lineWidth: 4)
                    .frame(width: 88, height: 88)
                
                // Inner circle / square
                if viewModel.isRecording {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red)
                        .frame(width: 32, height: 32)
                } else {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 72, height: 72)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.permissionDenied)
        .opacity(viewModel.permissionDenied ? 0.5 : 1.0)
    }
    
    // MARK: - Control Buttons
    private var controlButtons: some View {
        HStack(spacing: 40) {
            // Discard Button
            Button {
                showDiscardAlert = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.red.opacity(0.15)))
                    Text("Discard")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            
            // Pause/Resume Button
            Button {
                if viewModel.isPaused {
                    viewModel.resumeRecording()
                } else {
                    viewModel.pauseRecording()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.primaryColor)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.gray.opacity(0.15)))
                    Text(viewModel.isPaused ? "Resume" : "Pause")
                        .font(.caption2)
                        .foregroundColor(Theme.secondaryColor)
                }
            }
            
            // Save Button
            Button {
                viewModel.stopRecording()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.green))
                    Text("Save")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    // MARK: - Actions
    private func handleRecordTap() {
        switch viewModel.state {
        case .idle:
            viewModel.startRecording()
        case .recording:
            break
        case .paused:
            viewModel.resumeRecording()
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
