import CoreSpotlight
import UniformTypeIdentifiers

public enum SpotlightIndexer {

    /// Index a file's content for Spotlight search.
    public static func index(file: URL, content: String, domainID: String, displayName: String? = nil) {
        let attributes = CSSearchableItemAttributeSet(contentType: .plainText)
        attributes.title = file.lastPathComponent
        attributes.textContent = content
        attributes.contentURL = file
        attributes.contentModificationDate = Date()
        if let name = displayName {
            attributes.displayName = name
        }

        let item = CSSearchableItem(
            uniqueIdentifier: file.absoluteString,
            domainIdentifier: domainID,
            attributeSet: attributes
        )
        item.expirationDate = .distantFuture

        CSSearchableIndex.default().indexSearchableItems([item])
    }

    /// Remove a file from the Spotlight index.
    public static func deindex(file: URL) {
        CSSearchableIndex.default().deleteSearchableItems(
            withIdentifiers: [file.absoluteString]
        )
    }

    /// Remove all indexed items for a domain.
    public static func deindexAll(domainID: String) {
        CSSearchableIndex.default().deleteSearchableItems(
            withDomainIdentifiers: [domainID]
        )
    }
}
