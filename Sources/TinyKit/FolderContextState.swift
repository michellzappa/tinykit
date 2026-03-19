import Foundation
import FoundationModels

// MARK: - Folder Context File

public struct FolderContextFile: Identifiable {
    public var id: URL { url }
    public let url: URL
    public let name: String
    public let content: String
    public let tokenCount: Int
    public var isIncluded: Bool
}

// MARK: - Folder Context State

@MainActor
@Observable
public final class FolderContextState {
    public var files: [FolderContextFile] = []
    public var isExpanded: Bool = false
    public var isLoading: Bool = false

    /// Tokens used by system instructions.
    public private(set) var systemOverhead: Int = 0
    /// Tokens used by the current prompt text.
    public private(set) var promptTokens: Int = 0

    public var budgetTokens: Int {
        AIService.contextSize
    }

    public var includedFileTokens: Int {
        files.filter(\.isIncluded).reduce(0) { $0 + $1.tokenCount }
    }

    public var totalUsedTokens: Int {
        systemOverhead + promptTokens + includedFileTokens
    }

    public var availableTokens: Int {
        max(0, budgetTokens - totalUsedTokens)
    }

    public var includedCount: Int {
        files.filter(\.isIncluded).count
    }

    /// Concatenated content of included files, formatted for the AI prompt.
    public var includedContent: String? {
        let included = files.filter(\.isIncluded)
        guard !included.isEmpty else { return nil }
        return included.map { file in
            "--- \(file.name) ---\n\(file.content)"
        }.joined(separator: "\n\n")
    }

    public init() {}

    // MARK: - Loading

    public func loadFolder(url: URL?, extensions: Set<String>) {
        guard let url else {
            files = []
            return
        }

        isLoading = true

        let fm = FileManager.default
        let items = (try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        var loaded: [FolderContextFile] = []
        for item in items {
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            guard !isDir else { continue }
            guard extensions.contains(item.pathExtension.lowercased()) else { continue }

            if let content = try? String(contentsOf: item, encoding: .utf8) {
                let tokens = AIService.tokenCount(for: content)
                loaded.append(FolderContextFile(
                    url: item,
                    name: item.lastPathComponent,
                    content: content,
                    tokenCount: tokens,
                    isIncluded: false
                ))
            }
        }

        files = loaded.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        // Measure system overhead (approximate instruction tokens)
        let sampleInstructions = "You are a text editor assistant. Apply the user's instruction to the provided text. Return ONLY the modified text. Do not include explanations, markdown code fences, or commentary. The file type is .txt."
        systemOverhead = AIService.tokenCount(for: sampleInstructions)

        isLoading = false
    }

    // MARK: - Toggle

    public func toggle(_ file: FolderContextFile) {
        guard let idx = files.firstIndex(where: { $0.id == file.id }) else { return }
        files[idx].isIncluded.toggle()
    }

    /// Whether including this file would exceed the budget.
    public func wouldExceedBudget(_ file: FolderContextFile) -> Bool {
        guard !file.isIncluded else { return false }
        return file.tokenCount > availableTokens
    }

    // MARK: - Prompt tracking

    public func updatePromptTokens(for text: String) {
        promptTokens = text.isEmpty ? 0 : AIService.tokenCount(for: text)
    }

    // MARK: - Reset

    public func reset() {
        files = []
        isExpanded = false
        promptTokens = 0
    }
}
