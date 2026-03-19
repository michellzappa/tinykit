import SwiftUI

public struct CmdKInputBar: View {
    @Bindable var aiState: AIState
    var folderContext: FolderContextState?
    var onSubmit: () -> Void

    @FocusState private var isFocused: Bool
    @State private var speechRecognizer = SpeechRecognizer()

    public init(aiState: AIState, folderContext: FolderContextState? = nil, onSubmit: @escaping () -> Void) {
        self.aiState = aiState
        self.folderContext = folderContext
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(spacing: 0) {
            if !AIService.isAvailable {
                unavailableBanner
            } else {
                inputBar
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .frame(maxWidth: 600)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var unavailableBanner: some View {
        HStack {
            Image(systemName: "apple.intelligence")
                .foregroundStyle(.secondary)
            Text("Enable Apple Intelligence in System Settings")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Dismiss") { aiState.cancel() }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            // Expandable folder context panel
            if let ctx = folderContext, ctx.isExpanded {
                FolderContextView(context: ctx)
            }

            VStack(spacing: 6) {
                if !aiState.selectedText.isEmpty {
                    selectionPreview
                }

                HStack(spacing: 8) {
                    Picker("", selection: $aiState.mode) {
                        Text("Edit").tag(AIMode.edit)
                        Text("Ask").tag(AIMode.ask)
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()

                    if let ctx = folderContext, !ctx.files.isEmpty {
                        folderButton(ctx)
                    }

                    TextField("Describe what to do\u{2026}", text: $aiState.prompt)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                        .onSubmit { onSubmit() }
                        .onChange(of: aiState.prompt) { _, newValue in
                            folderContext?.updatePromptTokens(for: newValue)
                        }
                        .onKeyPress(.tab) {
                            aiState.mode = aiState.mode == .edit ? .ask : .edit
                            return .handled
                        }

                    if aiState.phase == .streaming {
                        ProgressView()
                            .controlSize(.small)
                        Button("Stop") { aiState.cancel() }
                            .buttonStyle(.plain)
                            .foregroundStyle(.red)
                    } else {
                        micButton
                        Button {
                            onSubmit()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .disabled(aiState.prompt.isEmpty)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                if let error = aiState.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)
                }

                if let ctx = folderContext, !ctx.files.isEmpty {
                    contextBar(ctx)
                }
            }
        }
        .onAppear { isFocused = true }
        .onDisappear { speechRecognizer.stopListening() }
        .onExitCommand { speechRecognizer.stopListening(); aiState.cancel() }
    }

    private var micButton: some View {
        Button {
            speechRecognizer.toggleListening { transcript in
                aiState.prompt = transcript
            }
        } label: {
            Image(systemName: speechRecognizer.isListening ? "mic.fill" : "mic")
                .font(.body)
                .foregroundStyle(speechRecognizer.isListening ? .red : .secondary)
        }
        .buttonStyle(.plain)
        .help("Dictate (voice to text)")
    }

    private func folderButton(_ ctx: FolderContextState) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                ctx.isExpanded.toggle()
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "folder")
                    .font(.body)
                    .foregroundStyle(ctx.includedCount > 0 ? .blue : .secondary)
                if ctx.includedCount > 0 {
                    Text("\(ctx.includedCount)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 3)
                        .background(Capsule().fill(.blue))
                        .offset(x: 6, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
        .help("Folder context (\(ctx.includedCount) files)")
    }

    private func contextBar(_ ctx: FolderContextState) -> some View {
        let total = CGFloat(ctx.budgetTokens)
        let used = CGFloat(ctx.totalUsedTokens)
        let fraction = total > 0 ? min(used / total, 1.0) : 0

        return HStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.quaternary)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(fraction > 0.95 ? .red : fraction > 0.8 ? .orange : .blue)
                        .frame(width: geo.size.width * fraction)
                }
                .frame(height: 4)
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 12)

            Text("\(ctx.totalUsedTokens)/\(ctx.budgetTokens)")
                .font(.system(size: 9).monospacedDigit())
                .foregroundStyle(.tertiary)
                .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    private var selectionPreview: some View {
        HStack {
            Image(systemName: "text.quote")
                .foregroundStyle(.secondary)
                .font(.caption)
            Text(aiState.selectedText.prefix(120).replacingOccurrences(of: "\n", with: " "))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }
}
