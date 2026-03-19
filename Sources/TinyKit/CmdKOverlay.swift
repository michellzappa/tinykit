import SwiftUI

// MARK: - Overlay Modifier

public struct CmdKOverlay: ViewModifier {
    @Bindable var aiState: AIState
    var editorBridge: EditorBridge
    var content: String
    var fileExtension: String?

    public init(aiState: AIState, editorBridge: EditorBridge, content: String, fileExtension: String?) {
        self.aiState = aiState
        self.editorBridge = editorBridge
        self.content = content
        self.fileExtension = fileExtension
    }

    public func body(content view: Content) -> some View {
        view
            .overlay(alignment: .top) {
                if aiState.phase == .inputting || aiState.phase == .streaming {
                    CmdKInputBar(aiState: aiState, folderContext: aiState.folderContext) {
                        aiState.submit(fullDocument: content, fileExtension: fileExtension)
                    }
                }
            }
            .overlay(alignment: .top) {
                if aiState.phase == .pendingAccept {
                    PendingAcceptBar(aiState: aiState)
                }
            }
            .overlay(alignment: .top) {
                if aiState.phase == .answerShowing {
                    VStack(spacing: 0) {
                        CmdKInputBar(aiState: aiState, folderContext: aiState.folderContext) {
                            aiState.submit(fullDocument: content, fileExtension: fileExtension)
                        }
                        AskAnswerPanel(aiState: aiState)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.15), value: aiState.phase == .idle)
    }
}

// MARK: - Pending Accept Bar

struct PendingAcceptBar: View {
    @Bindable var aiState: AIState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(.blue)

            Text("AI edit applied")
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Reject") { aiState.reject() }
                .keyboardShortcut(.escape, modifiers: [])

            Button("Accept") { aiState.accept() }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .frame(maxWidth: 600)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Answer Panel

struct AskAnswerPanel: View {
    @Bindable var aiState: AIState

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            ScrollView {
                Text(aiState.streamedResponse)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .frame(maxHeight: 300)

            Divider()

            HStack {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(aiState.streamedResponse, forType: .string)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Done") { aiState.dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(8)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .frame(maxWidth: 600)
        .padding(.horizontal, 12)
    }
}
