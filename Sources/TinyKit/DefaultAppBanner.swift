import SwiftUI
import UniformTypeIdentifiers

/// A banner that prompts the user to set this app as the default handler for its file types.
public struct DefaultAppBanner: View {
    let appName: String
    let associations: [FileTypeAssociation]

    @State private var nonDefault: [FileTypeAssociation] = []
    @State private var dismissed = FileAssociationManager.isBannerDismissed

    public init(appName: String, associations: [FileTypeAssociation]) {
        self.appName = appName
        self.associations = associations
    }

    public var body: some View {
        Group {
            if !dismissed && !nonDefault.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)

                    Text("\(appName) is not the default app for \(extensionList).")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Set as Default") {
                        FileAssociationManager.setAsDefault(for: nonDefault.map(\.utType))
                        withAnimation(.easeOut(duration: 0.2)) {
                            nonDefault = FileAssociationManager.nonDefaultTypes(from: associations)
                        }
                    }
                    .controlSize(.small)
                    .buttonStyle(.borderedProminent)

                    Button {
                        FileAssociationManager.isBannerDismissed = true
                        withAnimation(.easeOut(duration: 0.2)) {
                            dismissed = true
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.quaternary.opacity(0.5))
            }
        }
        .onAppear {
            nonDefault = FileAssociationManager.nonDefaultTypes(from: associations)
        }
    }

    private var extensionList: String {
        let exts = nonDefault.map { $0.label }
        if exts.count == 1 { return exts[0] }
        if exts.count == 2 { return "\(exts[0]) and \(exts[1])" }
        return exts.dropLast().joined(separator: ", ") + ", and " + (exts.last ?? "")
    }
}

public extension View {
    /// Adds a default-app banner above this view for the given file type associations.
    func defaultAppBanner(appName: String, associations: [FileTypeAssociation]) -> some View {
        VStack(spacing: 0) {
            DefaultAppBanner(appName: appName, associations: associations)
            self
        }
    }
}
