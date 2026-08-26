import Foundation
import Testing
@testable import YISU

@Suite("Session store")
struct SessionStoreTests {
    @Test @MainActor
    func restoreWithoutUserEndsSignedOut() async {
        let dependencies = TestAccountDependencies(currentUser: .success(nil))
        let store = dependencies.makeStore()

        await store.restore()

        #expect(store.state == .signedOut)
    }

    @Test @MainActor
    func restoreLoadsProfileAndWardrobeIntoReadyAccount() async {
        let dependencies = TestAccountDependencies(currentUser: .success(.fixture))
        let store = dependencies.makeStore()

        await store.restore()

        #expect(store.state == .ready(.fixture))
    }

    @Test @MainActor
    func signInMapsInvalidCredentialsAndPreservesSignedOutState() async {
        let dependencies = TestAccountDependencies(
            currentUser: .success(nil),
            signIn: .failure(AccountError.invalidCredentials)
        )
        let store = dependencies.makeStore()
        await store.restore()

        await store.signIn(email: "mia@example.com", password: "incorrect")

        #expect(store.state == .signedOut)
        #expect(store.submissionError == .invalidCredentials)
        #expect(!store.isSubmitting)
    }

    @Test @MainActor
    func accountLoadRetriesThreeTimesBeforeFailure() async {
        let dependencies = TestAccountDependencies(
            currentUser: .success(.fixture),
            profileResults: [
                .failure(AccountError.accountDataUnavailable),
                .failure(AccountError.accountDataUnavailable),
                .failure(AccountError.accountDataUnavailable)
            ]
        )
        let store = dependencies.makeStore()

        await store.restore()

        #expect(store.state == .failed(.accountDataUnavailable))
        #expect(dependencies.profile.fetchCount == 3)
        #expect(dependencies.sleepRecorder.durations == [.milliseconds(100), .milliseconds(250)])
    }

    @Test @MainActor
    func signOutClearsAccountEvenWhenRemoteSignOutThrows() async {
        let dependencies = TestAccountDependencies(
            currentUser: .success(.fixture),
            signOut: .failure(AccountError.networkUnavailable)
        )
        let store = dependencies.makeStore()
        await store.restore()

        await store.signOut()

        #expect(store.state == .signedOut)
    }

    @Test @MainActor
    func signedOutEventClearsAnExistingAccount() async {
        let dependencies = TestAccountDependencies(currentUser: .success(.fixture))
        let store = dependencies.makeStore()
        await store.restore()

        dependencies.auth.send(.signedOut)
        for _ in 0..<20 where store.state != .signedOut {
            await Task.yield()
        }

        #expect(store.state == .signedOut)
    }

    @Test @MainActor
    func profileUpdateReplacesReadyProfile() async {
        var updatedProfile = UserProfile.fixture
        updatedProfile.nickname = "Mia"
        let dependencies = TestAccountDependencies(
            currentUser: .success(.fixture),
            updatedProfile: .success(updatedProfile)
        )
        let store = dependencies.makeStore()
        await store.restore()

        await store.updateProfile(ProfileChanges(
            nickname: "Mia",
            languageCode: "zh-Hans",
            notificationsEnabled: true
        ))

        guard case let .ready(account) = store.state else {
            Issue.record("Expected a ready account")
            return
        }
        #expect(account.profile.nickname == "Mia")
    }
}

private final class AuthRepositorySpy: AuthRepository, @unchecked Sendable {
    private let queue = DispatchQueue(label: "AuthRepositorySpy")
    private let stream: AsyncStream<AuthSessionEvent>
    private let continuation: AsyncStream<AuthSessionEvent>.Continuation
    private let currentUserResult: Result<AuthenticatedUser?, AccountError>
    private let signInResult: Result<AuthenticatedUser, AccountError>
    private let signUpResult: Result<AuthenticatedUser, AccountError>
    private let signOutResult: Result<Void, AccountError>

    init(
        currentUser: Result<AuthenticatedUser?, AccountError>,
        signIn: Result<AuthenticatedUser, AccountError>,
        signUp: Result<AuthenticatedUser, AccountError>,
        signOut: Result<Void, AccountError>
    ) {
        let pair = AsyncStream.makeStream(of: AuthSessionEvent.self)
        stream = pair.stream
        continuation = pair.continuation
        currentUserResult = currentUser
        signInResult = signIn
        signUpResult = signUp
        signOutResult = signOut
    }

    func sessionEvents() -> AsyncStream<AuthSessionEvent> { stream }
    func currentUser() async throws -> AuthenticatedUser? { try currentUserResult.get() }
    func signUp(email: String, password: String) async throws -> AuthenticatedUser { try signUpResult.get() }
    func signIn(email: String, password: String) async throws -> AuthenticatedUser { try signInResult.get() }
    func signOut() async throws { try signOutResult.get() }
    func send(_ event: AuthSessionEvent) { queue.sync { continuation.yield(event) } }
}

private final class ProfileRepositorySpy: ProfileRepository, @unchecked Sendable {
    private let queue = DispatchQueue(label: "ProfileRepositorySpy")
    private var fetchResults: [Result<UserProfile, AccountError>]
    private let updatedProfile: Result<UserProfile, AccountError>
    private(set) var fetchCount = 0

    init(fetchResults: [Result<UserProfile, AccountError>], updatedProfile: Result<UserProfile, AccountError>) {
        self.fetchResults = fetchResults
        self.updatedProfile = updatedProfile
    }

    func fetchProfile() async throws -> UserProfile {
        try queue.sync {
            fetchCount += 1
            let result = fetchResults.count > 1 ? fetchResults.removeFirst() : fetchResults[0]
            return try result.get()
        }
    }

    func updateProfile(_ changes: ProfileChanges) async throws -> UserProfile {
        try updatedProfile.get()
    }
}

private final class WardrobeRepositorySpy: WardrobeRepository, @unchecked Sendable {
    let result: Result<WardrobeIdentity, AccountError>

    init(result: Result<WardrobeIdentity, AccountError>) {
        self.result = result
    }

    func fetchDefaultWardrobe() async throws -> WardrobeIdentity { try result.get() }
}

private final class SleepRecorder: @unchecked Sendable {
    private let queue = DispatchQueue(label: "SleepRecorder")
    private(set) var durations: [Duration] = []

    func sleep(for duration: Duration) async {
        queue.sync { durations.append(duration) }
    }
}

private final class TestAccountDependencies {
    let auth: AuthRepositorySpy
    let profile: ProfileRepositorySpy
    let wardrobe: WardrobeRepositorySpy
    let sleepRecorder = SleepRecorder()

    init(
        currentUser: Result<AuthenticatedUser?, AccountError>,
        signIn: Result<AuthenticatedUser, AccountError> = .success(.fixture),
        signUp: Result<AuthenticatedUser, AccountError> = .success(.fixture),
        signOut: Result<Void, AccountError> = .success(()),
        profileResults: [Result<UserProfile, AccountError>] = [.success(.fixture)],
        updatedProfile: Result<UserProfile, AccountError> = .success(.fixture),
        wardrobe: Result<WardrobeIdentity, AccountError> = .success(.fixture)
    ) {
        auth = AuthRepositorySpy(
            currentUser: currentUser,
            signIn: signIn,
            signUp: signUp,
            signOut: signOut
        )
        profile = ProfileRepositorySpy(fetchResults: profileResults, updatedProfile: updatedProfile)
        self.wardrobe = WardrobeRepositorySpy(result: wardrobe)
    }

    @MainActor
    func makeStore() -> SessionStore {
        SessionStore(
            authRepository: auth,
            profileRepository: profile,
            wardrobeRepository: wardrobe,
            sleep: { [sleepRecorder] duration in
                await sleepRecorder.sleep(for: duration)
            }
        )
    }
}

private extension AuthenticatedUser {
    static let fixture = AuthenticatedUser(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        email: "mia@example.com"
    )
}

private extension UserProfile {
    static let fixture = UserProfile(
        id: AuthenticatedUser.fixture.id,
        nickname: "衣序用户",
        avatarPath: nil,
        languageCode: "zh-Hans",
        notificationsEnabled: true,
        createdAt: Date(timeIntervalSince1970: 1_777_334_400),
        updatedAt: Date(timeIntervalSince1970: 1_777_334_400)
    )
}

private extension WardrobeIdentity {
    static let fixture = WardrobeIdentity(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
        ownerID: AuthenticatedUser.fixture.id,
        name: "我",
        isDefault: true
    )
}

private extension UserAccount {
    static let fixture = UserAccount(
        user: .fixture,
        profile: .fixture,
        defaultWardrobe: .fixture
    )
}
