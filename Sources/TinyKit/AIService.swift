import Foundation
import FoundationModels

public enum AIMode: String, CaseIterable, Identifiable, Sendable {
    case edit, ask
    public var id: String { rawValue }
}

public enum AIService {
    public struct Request: Sendable {
        public let prompt: String
        public let selectedText: String?
        public let fullDocument: String?
        public let folderContext: String?
        public let mode: AIMode
        public let fileExtension: String?

        public init(prompt: String, selectedText: String?, fullDocument: String?, folderContext: String? = nil, mode: AIMode, fileExtension: String?) {
            self.prompt = prompt
            self.selectedText = selectedText
            self.fullDocument = fullDocument
            self.folderContext = folderContext
            self.mode = mode
            self.fileExtension = fileExtension
        }
    }

    /// Check whether the on-device model is ready.
    public static var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    /// Total context window size in tokens.
    /// Apple's on-device model has a 4,096 token context window.
    /// TODO: Replace with SystemLanguageModel.default.contextSize when API is available.
    public static var contextSize: Int { 4096 }

    /// Estimate token count for a string.
    /// Uses ~4 characters per token heuristic for English text.
    /// TODO: Replace with SystemLanguageModel.default.tokenUsage(for:) when API is available.
    public static func tokenCount(for text: String) -> Int {
        max(1, text.utf8.count / 4)
    }

    public static func stream(_ request: Request) -> AsyncThrowingStream<String, Error> {
        guard isAvailable else {
            return AsyncThrowingStream { $0.finish(throwing: AIError.modelUnavailable) }
        }

        let ext = request.fileExtension ?? "txt"
        let instructions: String
        switch request.mode {
        case .edit:
            instructions = "You are a text editor assistant. Apply the user's instruction to the provided text. Return ONLY the modified text. Do not include explanations, markdown code fences, or commentary. The file type is .\(ext)."
        case .ask:
            instructions = "You are a helpful assistant. Answer the user's question concisely. If selected text is provided, use it as context. The file type is .\(ext)."
        }

        var msg = ""
        if let folder = request.folderContext, !folder.isEmpty {
            msg += "Project files for context:\n\(folder)\n\n"
        }
        if let selected = request.selectedText, !selected.isEmpty {
            msg += "Selected text:\n\(selected)\n\n"
        }
        msg += request.prompt
        let userMessage = msg

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let session = LanguageModelSession(instructions: instructions)
                    let stream = session.streamResponse(to: userMessage)
                    var previousLength = 0

                    for try await partial in stream {
                        if Task.isCancelled { break }
                        let content = partial.content
                        if content.count > previousLength {
                            let delta = String(content.dropFirst(previousLength))
                            continuation.yield(delta)
                            previousLength = content.count
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public enum AIError: LocalizedError {
        case modelUnavailable

        public var errorDescription: String? {
            switch self {
            case .modelUnavailable:
                return "On-device AI is not available. Enable Apple Intelligence in System Settings."
            }
        }
    }
}
