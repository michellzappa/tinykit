import SwiftUI

/// A reusable "Open Recent" submenu for the macOS menu bar.
public struct RecentFilesMenu: View {
    public let onOpen: (URL) -> Void

    public init(onOpen: @escaping (URL) -> Void) {
        self.onOpen = onOpen
    }

    public var body: some View {
        let recentURLs = RecentFiles.shared.files()
        Menu("Open Recent") {
            if recentURLs.isEmpty {
                Text("No Recent Files")
            } else {
                ForEach(recentURLs, id: \.self) { url in
                    Button(url.lastPathComponent) {
                        onOpen(url)
                    }
                }
                Divider()
                Button("Clear Recents") {
                    RecentFiles.shared.clearAll()
                }
            }
        }
    }
}
