import SwiftUI
import AppKit

public protocol AutoSavable: AnyObject {
    func saveAllDirtyTabs()
}

public struct WindowCloseGuard<State: AutoSavable>: NSViewRepresentable {
    public let state: State

    public init(state: State) {
        self.state = state
    }

    public func makeNSView(context: Context) -> NSView {
        let view = WindowCloseObserverView()
        view.onClose = { [weak state] in
            state?.saveAllDirtyTabs()
        }
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {}
}

private class WindowCloseObserverView: NSView {
    var onClose: (() -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose),
            name: NSWindow.willCloseNotification,
            object: window
        )
    }

    @objc private func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
