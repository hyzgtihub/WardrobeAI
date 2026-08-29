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
    func signOutInvalidatesAnInFlightAccountLoad() async {
        let fetchGate = AsyncGate()
        let dependencies = TestAccountDependencies(
            currentUser: .success(.fixture),
            fetchGate: fetchGate
        )
        let store = dependencies.makeStore()
        let restoreTask = Task { await store.restore() }
        for _ in 0..<100 where dependencies.profile.fetchCount == 0 {
            await Task.yield()
        }

        await store.signOut()
        await fetchGate.release()
        await restoreTask.value

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
        #expect(dependencies.profile.updatedUserID == AuthenticatedUser.fixture.id)
    }

    @Test @MainActor
    func profileUpdateShowsProgressAndSuppressesDuplicateSubmissions() async {
        let updateGate = AsyncGate()
        let dependencies = TestAccountDependencies(
            currentUser: .success(.fixture),
            updateGate: updateGate
        )
        let store = dependencies.makeStore()
        await store.restore()
        let changes = ProfileChanges(
            nickname: "Mia",
            languageCode: "zh-Hans",
            notificationsEnabled: true
        )

        let firstUpdate = Task { await store.updateProfile(changes) }
        for _ in 0..<100 where dependencies.profile.updateCount == 0 {
            await Task.yield()
        }
        #expect(store.isSubmitting)

        await store.updateProfile(changes)
        #expect(dependencies.profile.updateCount == 1)

        await updateGate.release()
        await firstUpdate.value
        #expect(!store.isSubmitting)
    }

    @Test @MainActor
    func signOutInvalidatesAnInFlightProfileUpdate() async {
        let updateGate = AsyncGate()
        let dependencies = TestAccountDependencies(
            currentUser: .success(.fixture),
            updateGate: updateGate
        )
        let store = dependencies.makeStore()
        await store.restore()
        let changes = ProfileChanges(
            nickname: "Former session",
            languageCode: "zh-Hans",
            notificationsEnabled: true
        )

        let updateTask = Task { await store.updateProfile(changes) }
        for _ in 0..<100 where dependencies.profile.updateCount == 0 {
            await Task.yield()
        }

        await store.signOut()
        await updateGate.release()
        await updateTask.value

        #expect(store.state == .signedOut)
        #expect(!store.isSubmitting)
        #expect(store.submissionError == nil)
    }

    @Test @MainActor
    func tokenRefreshDuringProfileUpdateStillClearsSubmissionProgress() async {
        let updateGate = AsyncGate()
        var updatedProfile = UserProfile.fixture
        updatedProfile.nickname = "Mia after refresh"
        let dependencies = TestAccountDependencies(
            currentUser: .success(.fixture),
            updatedProfile: .success(updatedProfile),
            updateGate: updateGate
        )
        let store = dependencies.makeStore()
        await store.restore()
        let changes = ProfileChanges(
            nickname: "Mia after refresh",
            languageCode: "zh-Hans",
            notificationsEnabled: true
        )

        let updateTask = Task { await store.updateProfile(changes) }
        for _ in 0..<100 where dependencies.profile.updateCount == 0 {
            await Task.yield()
        }
        dependencies.auth.send(.tokenRefreshed(.fixture))
        for _ in 0..<100 where dependencies.profile.fetchCount < 2 {
            await Task.yield()
        }

        await updateGate.release()
        await updateTask.value

        #expect(!store.isSubmitting)
        guard case let .ready(account) = store.state else {
            Issue.record("Expected refreshed account to remain ready")
            return
        }
        #expect(account.profile.nickname == "Mia after refresh")
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
    private let fetchGate: AsyncGate?
    private let updateGate: AsyncGate?
    private var storedFetchCount = 0
    private var storedUpdateCount = 0
    private var storedUpdatedUserID: UUID?

    var fetchCount: Int { queue.sync { storedFetchCount } }
    var updateCount: Int { queue.sync { storedUpdateCount } }
    var updatedUserID: UUID? { queue.sync { storedUpdatedUserID } }

    init(
        fetchResults: [Result<UserProfile, AccountError>],
        updatedProfile: Result<UserProfile, AccountError>,
        fetchGate: AsyncGate?,
        updateGate: AsyncGate?
    ) {
        self.fetchResults = fetchResults
        self.updatedProfile = updatedProfile
        self.fetchGate = fetchGate
        self.updateGate = updateGate
    }

    func fetchProfile() async throws -> UserProfile {
        let result = queue.sync {
            storedFetchCount += 1
            let result = fetchResults.count > 1 ? fetchResults.removeFirst() : fetchResults[0]
            return result
        }
        if let fetchGate { await fetchGate.wait() }
        return try result.get()
    }

    func updateProfile(_ changes: ProfileChanges, for userID: UUID) async throws -> UserProfile {
        queue.sync {
            storedUpdateCount += 1
            storedUpdatedUserID = userID
        }
        if let updateGate { await updateGate.wait() }
        return try updatedProfile.get()
    }
}

private actor AsyncGate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func release() {
        isOpen = true
        let pending = waiters
        waiters.removeAll()
        pending.forEach { $0.resume() }
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
        wardrobe: Result<WardrobeIdentity, AccountError> = .success(.fixture),
        fetchGate: AsyncGate? = nil,
        updateGate: AsyncGate? = nil
    ) {
        auth = AuthRepositorySpy(
            currentUser: currentUser,
            signIn: signIn,
            signUp: signUp,
            signOut: signOut
        )
        profile = ProfileRepositorySpy(
            fetchResults: profileResults,
            updatedProfile: updatedProfile,
            fetchGate: fetchGate,
            updateGate: updateGate
        )
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
