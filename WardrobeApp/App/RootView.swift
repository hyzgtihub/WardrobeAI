import SwiftUI

struct RootView: View {
    let sessionStore: SessionStore

    @State private var route: AppRoute
    @State private var setupState: WardrobeSetupState
    @State private var garments = WardrobeSampleData.garments
    @State private var selectedGarment = GarmentDetailDraft.whiteLinenShirt
    private let forcedScreen: String?

    init(sessionStore: SessionStore, arguments: [String] = ProcessInfo.processInfo.arguments) {
        self.sessionStore = sessionStore
        let screen = Self.argument(after: "-ui-screen", in: arguments)
        forcedScreen = screen
        let stateValue = Self.argument(after: "-ui-state", in: arguments)
        let initialRoute: AppRoute = switch screen {
        case "onboarding": .onboarding
        case "wardrobe": .wardrobe
        case "garment-detail": .garmentDetail
        default: .signIn
        }
        _route = State(initialValue: initialRoute)
        _setupState = State(initialValue: WardrobeSetupState(rawValue: stateValue ?? "") ?? .creating)
    }

    var body: some View {
        if ProcessInfo.processInfo.arguments.contains("-design-system-gallery") {
            DesignSystemGalleryView()
        } else {
            NavigationStack { content }
                .onChange(of: sessionStore.state) { _, state in
                    if forcedScreen == nil, state == .signedOut { route = .signIn }
                }
        }
    }

    @ViewBuilder private var content: some View {
        if forcedScreen != nil {
            routedContent
        } else {
            switch sessionStore.state {
            case .restoring:
                progress(title: "正在恢复登录状态")
            case .signedOut:
                authContent
            case .loadingAccount:
                progress(title: "正在准备你的衣橱")
            case let .ready(account):
                authenticatedContent(account: account)
            case let .failed(failure):
                failureContent(failure)
            }
        }
    }

    @ViewBuilder private var authContent: some View {
        if route == .signUp {
            SignUpView(
                isSubmitting: sessionStore.isSubmitting,
                error: nil,
                passwordTextContentType: .none,
                onBack: { route = .signIn },
                onCreated: { email, password in
                    await sessionStore.signUp(email: email, password: password)
                    if sessionStore.submissionError == nil { route = .signIn }
                    return sessionStore.submissionError
                }
            )
            .overlay(alignment: .top) {
                if let message = registrationErrorMessage {
                    Text(message)
                        .font(YISUTheme.Typography.footnote)
                        .foregroundStyle(YISUTheme.Color.danger)
                        .padding(YISUTheme.Spacing.md)
                        .background(YISUTheme.Color.dangerSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: YISUTheme.Radius.small))
                        .padding(.top, YISUTheme.Spacing.lg)
                        .accessibilityIdentifier("auth.error")
                }
            }
        } else {
            SignInView(
                isSubmitting: sessionStore.isSubmitting,
                error: sessionStore.submissionError,
                onRegister: { route = .signUp },
                onSubmit: { email, password in
                    await sessionStore.signIn(email: email, password: password)
                }
            )
        }
    }

    @ViewBuilder private func authenticatedContent(account: UserAccount) -> some View {
        if route == .profile {
            ProfileView(
                account: account,
                isSaving: sessionStore.isSubmitting,
                error: sessionStore.submissionError,
                onBack: { route = .wardrobe },
                onSave: { changes in await sessionStore.updateProfile(changes) },
                onSignOut: { await sessionStore.signOut() }
            )
        } else if route == .garmentDetail {
            garmentDetail
        } else {
            wardrobe
        }
    }

    @ViewBuilder private var routedContent: some View {
        switch route {
        case .signIn:
            SignInView(onRegister: { route = .signUp }, onSubmit: { _, _ in route = .wardrobe })
        case .signUp:
            SignUpView(onBack: { route = .signIn }, onCreated: { _, _ in
                route = .wardrobe
                return nil
            })
        case .onboarding:
            WardrobeSetupView(
                state: setupState,
                onRetry: { setupState = setupState == .currentRoleFailed ? .loadingCurrentRole : .creating },
                onContinue: {
                    if setupState == .created { setupState = .currentRole }
                    else if setupState == .currentRole { route = .wardrobe }
                }
            )
        case .wardrobe, .profile:
            wardrobe
        case .garmentDetail:
            garmentDetail
        }
    }

    private var wardrobe: some View {
        WardrobeHomeView(
            items: garments,
            onSelectGarment: { garment in
                if garment.id == GarmentDetailDraft.whiteLinenShirt.id {
                    selectedGarment = .whiteLinenShirt
                    route = .garmentDetail
                }
            },
            onProfile: { route = .profile }
        )
    }

    private var garmentDetail: some View {
        GarmentDetailView(
            garment: selectedGarment,
            onBack: { route = .wardrobe },
            onChange: { updated in
                selectedGarment = updated
                if let index = garments.firstIndex(where: { $0.id == updated.id }) {
                    garments[index] = updated.summary
                }
            },
            onDelete: { route = .wardrobe }
        )
    }

    private func progress(title: String) -> some View {
        YISUContentStateView(state: .loading, title: title, message: "请稍候…", actionTitle: nil, action: nil)
            .padding(YISUTheme.Spacing.lg)
            .background(YISUTheme.Color.background.ignoresSafeArea())
    }

    private func failureContent(_ failure: SessionFailure) -> some View {
        let message = switch failure {
        case .accountDataUnavailable: "账号资料尚未准备完成，请重试。"
        case .networkUnavailable: "网络连接不可用，请检查后重试。"
        case .unknown: "服务暂时不可用，请稍后重试。"
        }
        return YISUContentStateView(
            state: .error,
            title: "无法载入账号",
            message: message,
            actionTitle: "重试",
            action: { Task { await sessionStore.retryAccountLoad() } },
            actionAccessibilityIdentifier: "session.retry"
        )
        .padding(YISUTheme.Spacing.lg)
        .background(YISUTheme.Color.background.ignoresSafeArea())
    }

    private var registrationErrorMessage: String? {
        switch sessionStore.submissionError {
        case .emailAlreadyRegistered: "该邮箱已注册，请直接登录"
        case .networkUnavailable: "网络连接不可用，请稍后重试"
        case .invalidCredentials, .accountDataUnavailable, .invalidConfiguration, .unknown:
            "服务暂时不可用，请稍后重试"
        case nil: nil
        }
    }

    private static func argument(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}
