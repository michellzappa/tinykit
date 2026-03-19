import AppKit

public extension Notification.Name {
    static let showWelcome = Notification.Name("showWelcome")
}

public class TinyAppDelegate: NSObject, NSApplicationDelegate {
    public static var pendingFiles: [URL] = []
    public static var onOpenFiles: (([URL]) -> Void)?

    public func application(_ application: NSApplication, open urls: [URL]) {
        if let handler = Self.onOpenFiles {
            handler(urls)
        } else {
            Self.pendingFiles.append(contentsOf: urls)
        }
    }
}
