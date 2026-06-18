import SwiftUI

/// A large circular microphone button that pulses while recording.
struct MicButton: View {
    let isRecording: Bool
    let action: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isRecording {
                    Circle()
                        .stroke(Color.red.opacity(0.35), lineWidth: 8)
                        .frame(width: 96, height: 96)
                        .scaleEffect(pulse ? 1.45 : 1.0)
                        .opacity(pulse ? 0.0 : 1.0)
                }
                Circle()
                    .fill(isRecording ? Color.red : Color.accentColor)
                    .frame(width: 96, height: 96)
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: pulse)
        .onChange(of: isRecording) { _, recording in
            pulse = recording
        }
        .onAppear { pulse = isRecording }
        .accessibilityLabel(isRecording ? "Stop dictation" : "Start dictation")
    }
}
