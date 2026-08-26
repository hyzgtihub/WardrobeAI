import Foundation

@MainActor
struct AppDependencies {
    let sessionStore: SessionStore

    static func live() throws -> Self {
        let configuration = try SupabaseConfiguration.load()
        let client = SupabaseClientFactory.make(configuration: configuration)
        return Self(
            sessionStore: SessionStore(
                authRepository: SupabaseAuthRepository(client: client),
                profileRepository: SupabaseProfileRepository(client: client),
                wardrobeRepository: SupabaseWardrobeRepository(client: client)
            )
        )
    }

    static func uiTest(arguments: [String]) -> Self {
        let scenario = argument(after: "-ui-auth-scenario", in: arguments) ?? "signed-out"
        return Self(
            sessionStore: SessionStore(
                authRepository: UITestAuthRepository(scenario: scenario),
                profileRepository: UITestProfileRepository(),
                wardrobeRepository: UITestWardrobeRepository(),
                sleep: { _ in }
            )
        )
    }

    static func shouldUseUITestDependencies(arguments: [String]) -> Bool {
        arguments.contains("-ui-screen") ||
        arguments.contains("-ui-auth-scenario") ||
        arguments.contains("-design-system-gallery")
    }

    private static func argument(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}

private struct UITestAuthRepository: AuthRepository {
    let scenario: String

    func sessionEvents() -> AsyncStream<AuthSessionEvent> {
        AsyncStream { $0.finish() }
    }

    func currentUser() async throws -> AuthenticatedUser? {
        scenario == "signed-in" ? Self.user : nil
    }

    func signUp(email: String, password: String) async throws -> AuthenticatedUser {
        guard scenario != "registration-failure" else { throw AccountError.emailAlreadyRegistered }
        return Self.user
    }

    func signIn(email: String, password: String) async throws -> AuthenticatedUser {
        guard scenario == "login-success" else { throw AccountError.invalidCredentials }
        return Self.user
    }

    func signOut() async throws {}

    private static let user = AuthenticatedUser(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        email: "mia@example.com"
    )
}

private actor UITestProfileRepository: ProfileRepository {
    private var profile = UserProfile(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        nickname: "Mia",
        avatarPath: nil,
        languageCode: "zh-CN",
        notificationsEnabled: true,
        createdAt: Date(timeIntervalSince1970: 0),
        updatedAt: Date(timeIntervalSince1970: 0)
    )

    func fetchProfile() async throws -> UserProfile { profile }

    func updateProfile(_ changes: ProfileChanges) async throws -> UserProfile {
        profile.nickname = changes.nickname
        profile.languageCode = changes.languageCode
        profile.notificationsEnabled = changes.notificationsEnabled
        profile.updatedAt = Date()
        return profile
    }
}

private struct UITestWardrobeRepository: WardrobeRepository {
    func fetchDefaultWardrobe() async throws -> WardrobeIdentity {
        WardrobeIdentity(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            ownerID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "我",
            isDefault: true
        )
    }
}
