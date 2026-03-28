import AppKit
import WebKit
import UniformTypeIdentifiers

public enum ExportManager {

    // MARK: - Export PDF

    /// Retained during async PDF generation.
    nonisolated(unsafe) private static var pdfWebView: WKWebView?
    nonisolated(unsafe) private static var pdfDelegate: PDFNavigationDelegate?

    /// Export a complete HTML document as PDF via an offscreen WKWebView.
    public static func exportPDF(html: String, baseURL: URL? = nil, suggestedName: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = Self.changeExtension(suggestedName, to: "pdf")

        guard panel.runModal() == .OK, let saveURL = panel.url else { return }

        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 595, height: 842), configuration: config)
        let delegate = PDFNavigationDelegate(saveURL: saveURL)
        webView.navigationDelegate = delegate

        pdfWebView = webView
        pdfDelegate = delegate

        webView.loadHTMLString(html, baseURL: baseURL)
    }

    // MARK: - Export HTML

    /// Save a complete HTML document to a file.
    public static func exportHTML(html: String, suggestedName: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.html]
        panel.nameFieldStringValue = Self.changeExtension(suggestedName, to: "html")

        guard panel.runModal() == .OK, let url = panel.url else { return }

        try? html.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Copy as Plain Text

    /// Copy plain text (e.g. raw Markdown source) to the clipboard.
    public static func copyAsPlainText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    // MARK: - Copy as HTML Source

    /// Copy HTML source code to the clipboard as plain text.
    public static func copyAsHTMLSource(body: String, title: String = "document") {
        let html = wrapHTML(body: body, title: title)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(html, forType: .string)
    }

    // MARK: - Copy as Rich Text

    /// Copy HTML body content to the clipboard as rich text.
    public static func copyAsRichText(body: String) {
        let html = """
        <html><head><style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; font-size: 14px; line-height: 1.6; }
        code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 85%; background: #f6f8fa; padding: 0.2em 0.4em; border-radius: 4px; }
        pre { background: #f6f8fa; padding: 16px; border-radius: 6px; overflow: auto; }
        pre code { background: transparent; padding: 0; }
        blockquote { border-left: 3px solid #d0d7de; padding-left: 1em; color: #656d76; margin: 0 0 16px 0; }
        table { border-collapse: collapse; }
        th, td { border: 1px solid #d0d7de; padding: 6px 13px; }
        th { background: #f6f8fa; font-weight: 600; }
        .task.done, .task.cancelled { opacity: 0.5; text-decoration: line-through; }
        .note { padding-left: 24px; color: #656d76; font-style: italic; }
        </style></head><body>\(body)</body></html>
        """

        guard let data = html.data(using: .utf8),
              let attributed = NSAttributedString(html: data, documentAttributes: nil) else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([attributed])
    }

    // MARK: - HTML Document Builder

    /// Wrap an HTML body fragment in a complete, self-contained document with light/dark CSS.
    public static func wrapHTML(body: String, title: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="color-scheme" content="light dark">
        <title>\(Self.escapeHTML(title))</title>
        <style>
            :root {
                --text: #24292f;
                --bg: #ffffff;
                --code-bg: #f6f8fa;
                --border: #d0d7de;
                --muted: #656d76;
                --danger: #cf222e;
            }
            @media (prefers-color-scheme: dark) {
                :root {
                    --text: #e6edf3;
                    --bg: #0d1117;
                    --code-bg: #161b22;
                    --border: #30363d;
                    --muted: #8b949e;
                    --danger: #f85149;
                }
            }
            * { box-sizing: border-box; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
                font-size: 14px;
                line-height: 1.6;
                color: var(--text);
                background: var(--bg);
                max-width: 100%;
                padding: 20px 24px;
                margin: 0;
            }
            table {
                border-collapse: collapse;
                width: 100%;
                margin-bottom: 16px;
            }
            th, td {
                padding: 8px 12px;
                border: 1px solid var(--border);
                text-align: left;
            }
            th {
                background: var(--code-bg);
                font-weight: 600;
            }
            pre {
                background: var(--code-bg);
                padding: 16px;
                border-radius: 6px;
                overflow: auto;
                font-size: 13px;
                line-height: 1.45;
            }
            code {
                font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace;
            }
            h1, h2, h3 {
                margin-top: 24px;
                margin-bottom: 8px;
                font-weight: 600;
            }
            .task, .checklist {
                padding: 4px 0;
            }
            .task.done, .task.cancelled {
                opacity: 0.5;
                text-decoration: line-through;
            }
            .note {
                padding-left: 24px;
                color: var(--muted);
                font-style: italic;
            }
            .due {
                color: var(--danger);
                font-size: 12px;
            }
            .level-error { color: #cf222e; font-weight: 600; }
            .level-warn { color: #9a6700; }
            .level-info { color: #0550ae; }
            .level-debug { color: var(--muted); }
            .level-trace { color: var(--muted); opacity: 0.7; }
            @media (prefers-color-scheme: dark) {
                .level-error { color: #f85149; }
                .level-warn { color: #d29922; }
                .level-info { color: #58a6ff; }
            }
        </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }

    // MARK: - Helpers

    public static func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func changeExtension(_ name: String, to ext: String) -> String {
        let ns = name as NSString
        return ns.deletingPathExtension + "." + ext
    }

    // MARK: - PDF Delegate

    private class PDFNavigationDelegate: NSObject, WKNavigationDelegate {
        let saveURL: URL

        init(saveURL: URL) {
            self.saveURL = saveURL
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                webView.createPDF(configuration: .init()) { result in
                    if case .success(let data) = result {
                        try? data.write(to: self.saveURL)
                    }
                    ExportManager.pdfWebView = nil
                    ExportManager.pdfDelegate = nil
                }
            }
        }
    }
}
