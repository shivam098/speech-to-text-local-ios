import Foundation
import AVFoundation
import Speech
import Observation
#if canImport(UIKit)
import UIKit
#endif

/// Drives on-device speech recognition and exposes observable state to the UI.
@MainActor
@Observable
final class DictationModel {

    // MARK: - Observable state
    var rawTranscript: String = ""
    var isRecording: Bool = false
    var statusMessage: String = "Tap the mic and start speaking"
    var errorMessage: String?
    var cleanUpEnabled: Bool = true
    private(set) var isOnDeviceAvailable: Bool = false
    private(set) var elapsed: TimeInterval = 0

    // MARK: - Dependencies
    private let enhancer: TextEnhancer

    // MARK: - Speech / audio
    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // MARK: - Timing
    private var startDate: Date?
    private var timer: Timer?

    init(locale: Locale = Locale(identifier: "en-US"),
         enhancer: TextEnhancer = RuleBasedTextEnhancer()) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
        self.enhancer = enhancer
        self.isOnDeviceAvailable = speechRecognizer?.supportsOnDeviceRecognition ?? false
    }

    // MARK: - Derived values
    var displayedText: String {
        cleanUpEnabled ? enhancer.enhance(rawTranscript) : rawTranscript
    }

    var wordCount: Int {
        displayedText.split(whereSeparator: { $0 == " " || $0 == "\n" }).count
    }

    var wordsPerMinute: Int {
        guard elapsed > 1 else { return 0 }
        let words = rawTranscript.split(whereSeparator: { $0 == " " || $0 == "\n" }).count
        return Int(Double(words) / (elapsed / 60.0))
    }

    // MARK: - Control
    func toggle() async {
        if isRecording {
            stop()
        } else {
            await start()
        }
    }

    func start() async {
        errorMessage = nil
        guard await ensurePermissions() else { return }
        do {
            try beginRecognition()
            isRecording = true
            statusMessage = isOnDeviceAvailable ? "Listening — on-device" : "Listening…"
            startDate = Date()
            startTimer()
        } catch {
            errorMessage = error.localizedDescription
            stop()
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        timer?.invalidate()
        timer = nil
        if isRecording {
            statusMessage = "Tap the mic to dictate again"
        }
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func clear() {
        rawTranscript = ""
        elapsed = 0
        statusMessage = "Tap the mic and start speaking"
    }

    func copyToClipboard() {
        #if canImport(UIKit)
        UIPasteboard.general.string = displayedText
        #endif
    }

    // MARK: - Permissions
    private func ensurePermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { (cont: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        guard speechStatus == .authorized else {
            errorMessage = "Speech recognition permission is required. Enable it in Settings."
            return false
        }

        let micGranted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVAudioApplication.requestRecordPermission { cont.resume(returning: $0) }
        }
        guard micGranted else {
            errorMessage = "Microphone permission is required. Enable it in Settings."
            return false
        }

        guard speechRecognizer?.isAvailable == true else {
            errorMessage = "Speech recognition is not available right now."
            return false
        }
        return true
    }

    // MARK: - Engine
    private func beginRecognition() throws {
        recognitionTask?.cancel()
        recognitionTask = nil

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if speechRecognizer?.supportsOnDeviceRecognition == true {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let result {
                    self.rawTranscript = result.bestTranscription.formattedString
                }
                if let error {
                    self.errorMessage = error.localizedDescription
                    self.stop()
                }
            }
        }

        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let startDate = self.startDate else { return }
                self.elapsed = Date().timeIntervalSince(startDate)
            }
        }
    }
}
