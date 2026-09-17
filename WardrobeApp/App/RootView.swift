import SwiftUI

struct RootView: View {
    let dependencies: AppDependencies

    @State private var route: AppRoute
    @State private var setupState: WardrobeSetupState
    @State private var selectedGarment = GarmentDetailDraft.whiteLinenShirt
    @State private var garmentDetailStore: GarmentDetailStore
    @State private var addGarmentStore: AddGarmentStore
    @State private var garmentStore: GarmentStore
    @State private var photoPickerCancelRoute: AppRoute = .wardrobe
    @State private var wardrobeFilter = WardrobeFilter()
    @State private var filterOwnerUserID: UUID?
    private let forcedScreen: String?

    init(dependencies: AppDependencies, arguments: [String] = ProcessInfo.processInfo.arguments) {
        self.dependencies = dependencies
        let screen = Self.argument(after: "-ui-screen", in: arguments)
        forcedScreen = screen
        let stateValue = Self.argument(after: "-ui-state", in: arguments)
        let initialRoute: AppRoute = switch screen {
        case "onboarding": .onboarding
        case "wardrobe": .wardrobe
        case "add-garment": .garmentPhotoPicker
        case "garment-detail": .garmentDetail
        default: .signIn
        }
        _route = State(initialValue: initialRoute)
        _setupState = State(initialValue: WardrobeSetupState(rawValue: stateValue ?? "") ?? .creating)
        _addGarmentStore = State(initialValue: AddGarmentStore(
            garmentRepository: dependencies.garmentRepository,
            imageRepository: dependencies.garmentImageRepository
        ))
        _garmentStore = State(initialValue: GarmentStore(repository: dependencies.garmentRepository))
        _garmentDetailStore = State(initialValue: GarmentDetailStore(
            garment: Self.uiTestGarment,
            repository: dependencies.garmentRepository,
            imageRepository: dependencies.garmentImageRepository
        ))
    }

    private var sessionStore: SessionStore { dependencies.sessionStore }

    var body: some View {
        if ProcessInfo.processInfo.arguments.contains("-design-system-gallery") {
            DesignSystemGalleryView()
        } else {
            NavigationStack { content }
                .onChange(of: sessionStore.state) { _, state in
                    guard forcedScreen == nil else { return }
                    switch state {
                    case .signedOut:
                        garmentDetailStore.cancelPendingWork()
                        resetWardrobeFilter()
                        route = .signIn
                    case .ready(let account):
                        if filterOwnerUserID != account.user.id {
                            wardrobeFilter = WardrobeFilter()
                            filterOwnerUserID = account.user.id
                        }
                        if garmentDetailStore.garmentUserID != account.user.id {
                            garmentDetailStore.cancelPendingWork()
                            route = .wardrobe
                        }
                    default:
                        break
                    }
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
                onRequestCode: { email, password in
                    await sessionStore.requestSignUpVerification(email: email, password: password)
                    return sessionStore.submissionError
                },
                onResendCode: { email in
                    await sessionStore.resendSignUpVerification(email: email)
                    return sessionStore.submissionError
                },
                onVerifyCode: { email, code in
                    await sessionStore.verifySignUp(email: email, code: code)
                    return sessionStore.submissionError
                }
            )
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
        } else if route == .garmentPhotoPicker || route == .garmentPhotoPreview || route == .addGarment {
            addGarmentContent(account: account)
        } else {
            wardrobe(account: account)
        }
    }

    @ViewBuilder private var routedContent: some View {
        switch route {
        case .signIn:
            SignInView(onRegister: { route = .signUp }, onSubmit: { _, _ in route = .wardrobe })
        case .signUp:
            SignUpView(onBack: { route = .signIn }, onVerifyCode: { _, _ in
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
            wardrobe(account: Self.uiTestAccount)
        case .garmentPhotoPicker, .garmentPhotoPreview, .addGarment:
            addGarmentContent(account: Self.uiTestAccount)
        case .garmentDetail:
            garmentDetail
        }
    }

    private func wardrobe(account: UserAccount) -> some View {
        WardrobeHomeView(
            garments: garmentStore.garments,
            filter: wardrobeFilterBinding(for: account.user.id),
            state: garmentStore.state,
            imageRepository: dependencies.garmentImageRepository,
            onAdd: {
                addGarmentStore.startNewFlow()
                photoPickerCancelRoute = .wardrobe
                route = .garmentPhotoPicker
            },
            onSelectGarment: { garment in
                if let persisted = garmentStore.garments.first(where: { $0.id == garment.id }) {
                    openDetail(persisted)
                }
            },
            onProfile: { route = .profile }
        )
        .task(id: account.defaultWardrobe.id) {
            prepareWardrobeFilter(for: account.user.id)
            await garmentStore.load(wardrobeID: account.defaultWardrobe.id)
        }
    }

    private func wardrobeFilterBinding(for userID: UUID) -> Binding<WardrobeFilter> {
        Binding(
            get: {
                guard filterOwnerUserID == nil || filterOwnerUserID == userID else {
                    return WardrobeFilter()
                }
                return wardrobeFilter
            },
            set: { newValue in
                if filterOwnerUserID != userID {
                    filterOwnerUserID = userID
                }
                wardrobeFilter = newValue
            }
        )
    }

    private func prepareWardrobeFilter(for userID: UUID) {
        guard filterOwnerUserID != userID else { return }
        wardrobeFilter = WardrobeFilter()
        filterOwnerUserID = userID
    }

    private func resetWardrobeFilter() {
        wardrobeFilter = WardrobeFilter()
        filterOwnerUserID = nil
    }

    @ViewBuilder private func addGarmentContent(account: UserAccount) -> some View {
        switch route {
        case .garmentPhotoPicker:
            GarmentPhotoPickerView(
                injectedPhotoData: dependencies.addGarmentFixtureData,
                onPhotoSelected: { data in
                    addGarmentStore.processPhoto(data)
                    if addGarmentStore.state == .editing { route = .garmentPhotoPreview }
                },
                onCancel: { route = photoPickerCancelRoute }
            )
        case .garmentPhotoPreview:
            if let photo = addGarmentStore.draft.photo {
                GarmentPhotoPreviewView(
                    photo: photo,
                    onReselect: {
                        photoPickerCancelRoute = .garmentPhotoPreview
                        route = .garmentPhotoPicker
                    },
                    onUsePhoto: { route = .addGarment }
                )
            } else {
                GarmentPhotoPickerView(
                    injectedPhotoData: dependencies.addGarmentFixtureData,
                    onPhotoSelected: { data in
                        addGarmentStore.processPhoto(data)
                        if addGarmentStore.state == .editing { route = .garmentPhotoPreview }
                    },
                    onCancel: { route = photoPickerCancelRoute }
                )
            }
        case .addGarment:
            AddGarmentView(
                store: addGarmentStore,
                account: account,
                onBack: {
                    addGarmentStore.discardDraft()
                    route = .wardrobe
                },
                onReselectPhoto: {
                    photoPickerCancelRoute = .addGarment
                    route = .garmentPhotoPicker
                },
                onCreated: { garment in
                    garmentStore.insertCreated(garment)
                    openDetail(garment)
                }
            )
        default:
            EmptyView()
        }
    }

    private var garmentDetail: some View {
        GarmentDetailView(
            store: garmentDetailStore,
            onBack: { route = .wardrobe },
            imageRepository: dependencies.garmentImageRepository,
            onChangePhoto: {},
            onDelete: {
                Task {
                    if await garmentDetailStore.delete() {
                        garmentStore.removePersisted(id: garmentDetailStore.draft.id)
                        route = .wardrobe
                    }
                }
            }
        )
    }

    private func openDetail(_ garment: Garment) {
        let detail = GarmentDetailStore(
            garment: garment,
            repository: dependencies.garmentRepository,
            imageRepository: dependencies.garmentImageRepository
        )
        detail.setOnPersisted { persisted in garmentStore.replacePersisted(persisted) }
        garmentDetailStore = detail
        selectedGarment = GarmentDetailDraft(garment: garment)
        route = .garmentDetail
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

    private static func argument(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    private static let uiTestAccount = UserAccount(
        user: AuthenticatedUser(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            email: "mia@example.com"
        ),
        profile: UserProfile(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            nickname: "Mia",
            avatarPath: nil,
            languageCode: "zh-CN",
            notificationsEnabled: true,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0)
        ),
        defaultWardrobe: WardrobeIdentity(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            ownerID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "我",
            isDefault: true
        )
    )

    private static let uiTestGarment = Garment(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111101")!,
        userID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        wardrobeID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        imagePath: "garment-white-linen-shirt", name: "白色亚麻衬衫", category: .tops,
        seasons: ["春季", "夏季"], colors: ["白色系"], brand: "MUJI", price: 299, size: "M",
        purchaseDate: nil, materials: ["麻", "棉"], styles: ["通勤", "简约"],
        storageLocation: "主卧衣橱 · 上层", notes: "适合搭配浅色长裤", createdAt: Date(), updatedAt: Date(), deletedAt: nil
    )

}
