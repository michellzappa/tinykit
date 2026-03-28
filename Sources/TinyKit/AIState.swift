import Foundation
import AppKit

@MainActor
@Observable
public final class AIState {
    public enum Phase { case idle, inputting, streaming, pendingAccept, answerShowing }

    public var phase: Phase = .idle
    public var mode: AIMode = .edit
    public var prompt: String = ""
    public var selectedText: String = ""
    public var selectedRange: NSRange = NSRange(location: 0, length: 0)
    public var streamedResponse: String = ""
    public var originalText: String = ""
    public var error: String?
    public weak var editorBridge: EditorBridge?
    public var folderContext = FolderContextState()

    private var streamTask: Task<Void, Never>?
    private var insertionPoint: Int = 0
    private var isFirstToken = true

    public init() {}

    public func activate(selection: String, range: NSRange, bridge: EditorBridge?, folderURL: URL? = nil, supportedExtensions: Set<String> = []) {
        mode = bridge == nil ? .ask : .edit
        selectedText = selection
        selectedRange = range
        originalText = selection
        editorBridge = bridge
        prompt = ""
        streamedResponse = ""
        error = nil
        folderContext.reset()
        if folderURL != nil {
            folderContext.loadFolder(url: folderURL, extensions: supportedExtensions)
        }
        phase = .inputting
    }

    public func submit(fullDocument: String?, fileExtension: String?) {
        guard !prompt.isEmpty else { return }
        phase = .streaming
        streamedResponse = ""
        error = nil
        isFirstToken = true
        insertionPoint = selectedRange.location

        let request = AIService.Request(
            prompt: prompt,
            selectedText: selectedText.isEmpty ? nil : selectedText,
            fullDocument: fullDocument,
            folderContext: folderContext.includedContent,
            mode: mode,
            fileExtension: fileExtension
        )

        streamTask = Task {
            do {
                for try await token in AIService.stream(request) {
                    streamedResponse += token

                    if mode == .edit, let bridge = editorBridge {
                        if isFirstToken {
                            // Replace the selected range with the first token
                            bridge.replaceRange(selectedRange, with: token)
                            insertionPoint = selectedRange.location + token.utf16.count
                            isFirstToken = false
                        } else {
                            // Insert subsequent tokens at the insertion point
                            bridge.insertText(at: insertionPoint, text: token)
                            insertionPoint += token.utf16.count
                        }
                        // Highlight the AI-written range
                        let aiRange = NSRange(
                            location: selectedRange.location,
                            length: insertionPoint - selectedRange.location
                        )
                        bridge.highlightRange(aiRange, color: NSColor.systemBlue.withAlphaComponent(0.15))
                    }
                }
                phase = mode == .edit ? .pendingAccept : .answerShowing
            } catch {
                if mode == .edit, !isFirstToken {
                    // Restore original text on error mid-stream
                    rejectEdit()
                }
                self.error = error.localizedDescription
                phase = .inputting
            }
        }
    }

    public func cancel() {
        streamTask?.cancel()
        streamTask = nil
        if mode == .edit && phase == .streaming && !isFirstToken {
            rejectEdit()
        }
        editorBridge?.clearHighlight()
        reset()
    }

    public func accept() {
        editorBridge?.clearHighlight()
        reset()
    }

    public func reject() {
        rejectEdit()
        editorBridge?.clearHighlight()
        reset()
    }

    public func dismiss() {
        reset()
    }

    private func rejectEdit() {
        guard let bridge = editorBridge else { return }
        let editedRange = NSRange(
            location: selectedRange.location,
            length: insertionPoint - selectedRange.location
        )
        bridge.replaceRange(editedRange, with: originalText)
    }

    private func reset() {
        phase = .idle
        prompt = ""
        selectedText = ""
        streamedResponse = ""
        originalText = ""
        error = nil
    }
}
