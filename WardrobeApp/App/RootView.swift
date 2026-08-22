import SwiftUI

struct RootView: View {
    @State private var route: AppRoute
    @State private var setupState: WardrobeSetupState

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        let screen = Self.argument(after: "-ui-screen", in: arguments)
        let stateValue = Self.argument(after: "-ui-state", in: arguments)
        _route = State(initialValue: screen == "onboarding" ? .onboarding : .signIn)
        _setupState = State(initialValue: WardrobeSetupState(rawValue: stateValue ?? "") ?? .creating)
    }

    var body: some View {
        if ProcessInfo.processInfo.arguments.contains("-design-system-gallery") {
            DesignSystemGalleryView()
        } else {
            NavigationStack {
                switch route {
                case .signIn:
                    SignInView(onRegister: { route = .signUp }, onSubmit: { _, _ in route = .onboarding })
                case .signUp:
                    SignUpView(onBack: { route = .signIn }, onCreated: { _, _ in route = .onboarding })
                case .onboarding:
                    WardrobeSetupView(
                        state: setupState,
                        onRetry: { setupState = setupState == .currentRoleFailed ? .loadingCurrentRole : .creating },
                        onContinue: {
                            if setupState == .created { setupState = .currentRole }
                            else if setupState == .currentRole { route = .wardrobe }
                        }
                    )
                case .wardrobe:
                    Text("衣橱首页")
                        .font(YISUTheme.Typography.largeTitle)
                }
            }
        }
    }

    private static func argument(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}
