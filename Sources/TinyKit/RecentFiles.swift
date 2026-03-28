import Foundation

/// Tracks recently opened files per-app, persisted via security-scoped bookmarks.
@Observable
public final class RecentFiles {
    public static let shared = RecentFiles()

    private let defaults: UserDefaults
    private static let key = "recentFileEntries"
    private static let maxEntries = 10

    /// Cached entries loaded from disk.
    private var entries: [Entry] = []

    public init(suiteName: String = "com.tiny.shared") {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
        self.entries = Self.loadEntries(from: defaults)
    }

    // MARK: - Public API

    /// Record a file open. Moves to top if already present.
    public func add(_ url: URL, appID: String? = nil) {
        let id = appID ?? (Bundle.main.bundleIdentifier ?? "unknown")
        guard let bookmark = try? url.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }

        // Remove existing entry for same path + app
        let standardized = url.standardizedFileURL
        entries.removeAll { $0.appID == id && $0.url?.standardizedFileURL == standardized }

        // Insert at front
        entries.insert(Entry(bookmark: bookmark, appID: id, timestamp: Date()), at: 0)

        // Trim per-app to max
        var countPerApp: [String: Int] = [:]
        entries = entries.filter { entry in
            let c = (countPerApp[entry.appID] ?? 0) + 1
            countPerApp[entry.appID] = c
            return c <= Self.maxEntries
        }

        save()
    }

    /// Returns recent file URLs for the given app, most recent first.
    /// Filters out files that no longer exist.
    public func files(for appID: String? = nil) -> [URL] {
        let id = appID ?? (Bundle.main.bundleIdentifier ?? "unknown")
        return entries
            .filter { $0.appID == id }
            .compactMap { $0.url }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    /// Clear all recent entries for the given app.
    public func clearAll(for appID: String? = nil) {
        let id = appID ?? (Bundle.main.bundleIdentifier ?? "unknown")
        entries.removeAll { $0.appID == id }
        save()
    }

    // MARK: - Persistence

    private struct Entry {
        let bookmark: Data
        let appID: String
        let timestamp: Date

        /// Resolved URL (nil if bookmark is stale/invalid).
        var url: URL? {
            var isStale = false
            guard let url = try? URL(
                resolvingBookmarkData: bookmark,
                options: [],
                bookmarkDataIsStale: &isStale
            ) else { return nil }
            return url
        }
    }

    private static func loadEntries(from defaults: UserDefaults) -> [Entry] {
        guard let array = defaults.array(forKey: key) as? [[String: Any]] else { return [] }
        return array.compactMap { dict in
            guard let bookmark = dict["bookmark"] as? Data,
                  let appID = dict["appID"] as? String,
                  let timestamp = dict["timestamp"] as? Date else { return nil }
            return Entry(bookmark: bookmark, appID: appID, timestamp: timestamp)
        }
    }

    private func save() {
        let array: [[String: Any]] = entries.map { entry in
            [
                "bookmark": entry.bookmark,
                "appID": entry.appID,
                "timestamp": entry.timestamp,
            ]
        }
        defaults.set(array, forKey: Self.key)
    }
}
