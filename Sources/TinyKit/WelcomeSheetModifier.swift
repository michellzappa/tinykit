import SwiftUI

struct WelcomeSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let appName: String
    let subtitle: String
    let features: [(icon: String, title: String, description: String)]
    let openButtonTitle: String
    let onOpen: () -> Void
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                TinyWelcomeView(
                    appName: appName,
                    subtitle: subtitle,
                    features: features,
                    openButtonTitle: openButtonTitle,
                    onOpenFolder: {
                        WelcomeState.markLaunched()
                        isPresented = false
                        onOpen()
                    },
                    onDismiss: {
                        WelcomeState.markLaunched()
                        isPresented = false
                        onDismiss()
                    }
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: .showWelcome)) { _ in
                isPresented = true
            }
    }
}

public extension View {
    func welcomeSheet(
        isPresented: Binding<Bool>,
        appName: String,
        subtitle: String,
        features: [(icon: String, title: String, description: String)],
        openButtonTitle: String = "Open a Folder",
        onOpen: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(WelcomeSheetModifier(
            isPresented: isPresented,
            appName: appName,
            subtitle: subtitle,
            features: features,
            openButtonTitle: openButtonTitle,
            onOpen: onOpen,
            onDismiss: onDismiss
        ))
    }
}
