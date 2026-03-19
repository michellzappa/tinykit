import SwiftUI

public struct FolderContextView: View {
    @Bindable var context: FolderContextState

    public init(context: FolderContextState) {
        self.context = context
    }

    public var body: some View {
        VStack(spacing: 0) {
            budgetBar
            Divider().opacity(0.5)
            fileList
            Divider().opacity(0.5)
            budgetBreakdown
        }
        .padding(.top, 4)
    }

    // MARK: - Budget Bar

    private var budgetBar: some View {
        HStack(spacing: 8) {
            GeometryReader { geo in
                let total = CGFloat(context.budgetTokens)
                let used = CGFloat(context.totalUsedTokens)
                let fraction = total > 0 ? min(used / total, 1.0) : 0

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.quaternary)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor(fraction: fraction))
                        .frame(width: geo.size.width * fraction)
                }
                .frame(height: 6)
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 16)

            Text("\(context.totalUsedTokens) / \(context.budgetTokens)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private func barColor(fraction: CGFloat) -> Color {
        if fraction > 0.95 { return .red }
        if fraction > 0.8 { return .orange }
        return .blue
    }

    // MARK: - File List

    private var fileList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if context.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .padding(8)
                } else if context.files.isEmpty {
                    Text("No files in folder")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(8)
                } else {
                    ForEach(context.files) { file in
                        fileRow(file)
                    }
                }
            }
        }
        .frame(maxHeight: 180)
    }

    private func fileRow(_ file: FolderContextFile) -> some View {
        let exceeds = context.wouldExceedBudget(file)

        return Button {
            context.toggle(file)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: file.isIncluded ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(file.isIncluded ? Color.blue : Color.secondary)
                    .font(.caption)

                Text(file.name)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                if exceeds && !file.isIncluded {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                Text("\(file.tokenCount)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(exceeds && !file.isIncluded ? 0.5 : 1.0)
    }

    // MARK: - Budget Breakdown

    private var budgetBreakdown: some View {
        HStack(spacing: 12) {
            label("System", value: context.systemOverhead)
            label("Prompt", value: context.promptTokens)
            label("Files", value: context.includedFileTokens)
            Spacer()
            Text("\(context.availableTokens) free")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private func label(_ title: String, value: Int) -> some View {
        HStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text("\(value)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}
