import SwiftUI

@main
struct YISUApp: App {
    private let dependencies: AppDependencies?

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        if AppDependencies.shouldUseUITestDependencies(arguments: arguments) {
            dependencies = AppDependencies.uiTest(arguments: arguments)
        } else {
            dependencies = try? AppDependencies.live()
        }
    }

    var body: some Scene {
        WindowGroup {
            if let dependencies {
                RootView(sessionStore: dependencies.sessionStore)
                    .task { await dependencies.sessionStore.restore() }
            } else {
                ConfigurationErrorView()
            }
        }
    }
}

private struct ConfigurationErrorView: View {
    var body: some View {
        YISUContentStateView(
            state: .error,
            title: "应用配置不可用",
            message: "请检查本地 Supabase 配置后重新启动应用。",
            actionTitle: nil,
            action: nil
        )
        .padding(YISUTheme.Spacing.lg)
        .background(YISUTheme.Color.background.ignoresSafeArea())
    }
}
