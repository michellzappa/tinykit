import Foundation
import Speech
import AVFoundation

@MainActor
@Observable
public final class SpeechRecognizer {
    public var isListening = false
    public var transcript = ""

    private var audioEngine = AVAudioEngine()
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    public init() {}

    public static var isAvailable: Bool {
        SFSpeechRecognizer()?.isAvailable ?? false
    }

    public func toggleListening(onTranscript: ((String) -> Void)? = nil) {
        if isListening {
            stopListening()
        } else {
            startListening(onTranscript: onTranscript)
        }
    }

    public func startListening(onTranscript: ((String) -> Void)? = nil) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard status == .authorized else { return }
                self?.beginRecording(onTranscript: onTranscript)
            }
        }
    }

    public func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isListening = false
    }

    private func beginRecording(onTranscript: ((String) -> Void)?) {
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else { return }

        // Use on-device recognition if available
        let request = SFSpeechAudioBufferRecognitionRequest()
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        request.shouldReportPartialResults = true
        self.recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
        } catch {
            stopListening()
            return
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    onTranscript?(self.transcript)
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.stopListening()
                }
            }
        }
    }
}
