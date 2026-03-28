import Foundation
import UniformTypeIdentifiers
import CoreServices

public struct FileTypeAssociation {
    public let utType: UTType
    public let label: String

    public init(utType: UTType, label: String) {
        self.utType = utType
        self.label = label
    }
}

public enum FileAssociationManager {

    /// The bundle identifier of the running app.
    private static var bundleID: String {
        Bundle.main.bundleIdentifier ?? ""
    }

    /// Check if this app is the default handler for a given UTType.
    public static func isDefault(for utType: UTType) -> Bool {
        guard let current = LSCopyDefaultRoleHandlerForContentType(
            utType.identifier as CFString, .all
        )?.takeRetainedValue() as String? else {
            return false
        }
        return current.caseInsensitiveCompare(bundleID) == .orderedSame
    }

    /// Set this app as the default handler for the given UTTypes.
    public static func setAsDefault(for types: [UTType]) {
        let bid = bundleID as CFString
        for utType in types {
            LSSetDefaultRoleHandlerForContentType(
                utType.identifier as CFString,
                .all,
                bid
            )
        }
    }

    /// Return the subset of associations where this app is NOT the current default.
    public static func nonDefaultTypes(from associations: [FileTypeAssociation]) -> [FileTypeAssociation] {
        associations.filter { !isDefault(for: $0.utType) }
    }

    /// UserDefaults key for dismissing the banner.
    public static let dismissedKey = "fileAssociationBannerDismissed"

    /// Whether the user has permanently dismissed the banner.
    public static var isBannerDismissed: Bool {
        get { UserDefaults.standard.bool(forKey: dismissedKey) }
        set { UserDefaults.standard.set(newValue, forKey: dismissedKey) }
    }
}
