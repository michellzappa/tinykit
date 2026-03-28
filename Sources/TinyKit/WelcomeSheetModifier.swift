import SwiftUI

struct WelcomeSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let appName: String
    let subtitle: String
    let features: [(icon: String, title: String, description: String)]
    let onOpenFolder: () -> Void
    let onOpenFile: (() -> Void)?
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                TinyWelcomeView(
                    appName: appName,
                    subtitle: subtitle,
                    features: features,
                    onOpenFolder: {
                        WelcomeState.markLaunched()
                        isPresented = false
                        onOpenFolder()
                    },
                    onOpenFile: onOpenFile.map { action in
                        {
                            WelcomeState.markLaunched()
                            isPresented = false
                            action()
                        }
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
        onOpenFolder: @escaping () -> Void,
        onOpenFile: (() -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(WelcomeSheetModifier(
            isPresented: isPresented,
            appName: appName,
            subtitle: subtitle,
            features: features,
            onOpenFolder: onOpenFolder,
            onOpenFile: onOpenFile,
            onDismiss: onDismiss
        ))
    }
}
