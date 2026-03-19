import AppKit

@Observable
public final class EditorBridge {
    public weak var textView: NSTextView?

    public init() {}

    public var currentSelection: String {
        guard let tv = textView else { return "" }
        let sel = tv.selectedRange()
        guard sel.length > 0, let storage = tv.textStorage else { return "" }
        return (storage.string as NSString).substring(with: sel)
    }

    public var currentSelectedRange: NSRange {
        textView?.selectedRange() ?? NSRange(location: 0, length: 0)
    }

    public func replaceRange(_ range: NSRange, with text: String) {
        guard let tv = textView else { return }
        tv.insertText(text, replacementRange: range)
    }

    public func insertText(at location: Int, text: String) {
        guard let tv = textView else { return }
        tv.insertText(text, replacementRange: NSRange(location: location, length: 0))
    }

    public func highlightRange(_ range: NSRange, color: NSColor) {
        guard let tv = textView, let layoutManager = tv.layoutManager else { return }
        layoutManager.addTemporaryAttribute(
            .backgroundColor,
            value: color,
            forCharacterRange: range
        )
    }

    public func clearHighlight() {
        guard let tv = textView, let layoutManager = tv.layoutManager, let storage = tv.textStorage else { return }
        layoutManager.removeTemporaryAttribute(
            .backgroundColor,
            forCharacterRange: NSRange(location: 0, length: storage.length)
        )
    }
}
