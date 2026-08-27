import Foundation
import Observation

enum SessionFailure: Equatable, Sendable {
    case accountDataUnavailable
    case networkUnavailable
    case unknown
}

enum SessionState: Equatable, Sendable {
    case restoring
    case signedOut
    case loadingAccount(AuthenticatedUser)
    case ready(UserAccount)
    case failed(SessionFailure)
}

@MainActor
@Observable
final class SessionStore {
    typealias Sleep = @Sendable (Duration) async -> Void

    private(set) var state: SessionState = .restoring
    private(set) var isSubmitting = false
    private(set) var submissionError: AccountError?

    private let authRepository: any AuthRepository
    private let profileRepository: any ProfileRepository
    private let wardrobeRepository: any WardrobeRepository
    private let sleep: Sleep
    private var lastUser: AuthenticatedUser?
    private var accountLoadGeneration = 0
    private var submissionGeneration = 0
    private nonisolated(unsafe) var eventTask: Task<Void, Never>?

    init(
        authRepository: any AuthRepository,
        profileRepository: any ProfileRepository,
        wardrobeRepository: any WardrobeRepository,
        sleep: @escaping Sleep = { duration in try? await Task.sleep(for: duration) }
    ) {
        self.authRepository = authRepository
        self.profileRepository = profileRepository
        self.wardrobeRepository = wardrobeRepository
        self.sleep = sleep

        eventTask = Task { [weak self, authRepository] in
            for await event in authRepository.sessionEvents() {
                guard let self else { return }
                await self.handle(event)
            }
        }
    }

    deinit {
        eventTask?.cancel()
    }

    func restore() async {
        state = .restoring
        submissionError = nil
        do {
            guard let user = try await authRepository.currentUser() else {
                clearLocalAccount()
                return
            }
            await loadAccount(for: user)
        } catch {
            clearLocalAccount()
        }
    }

    func signIn(email: String, password: String) async {
        guard !isSubmitting else { return }
        let submission = beginSubmission()
        submissionError = nil
        defer { finishSubmission(submission) }

        do {
            let user = try await authRepository.signIn(email: email, password: password)
            await loadAccount(for: user)
        } catch {
            state = .signedOut
            submissionError = accountError(from: error)
        }
    }

    func signUp(email: String, password: String) async {
        guard !isSubmitting else { return }
        let submission = beginSubmission()
        submissionError = nil
        defer { finishSubmission(submission) }

        do {
            let user = try await authRepository.signUp(email: email, password: password)
            await loadAccount(for: user)
        } catch {
            state = .signedOut
            submissionError = accountError(from: error)
        }
    }

    func retryAccountLoad() async {
        guard let lastUser else {
            state = .signedOut
            return
        }
        await loadAccount(for: lastUser)
    }

    func updateProfile(_ changes: ProfileChanges) async {
        guard !isSubmitting, case var .ready(account) = state else { return }
        let generation = accountLoadGeneration
        let submission = beginSubmission()
        submissionError = nil
        defer { finishSubmission(submission) }
        do {
            account.profile = try await profileRepository.updateProfile(changes)
            guard generation == accountLoadGeneration,
                  case let .ready(currentAccount) = state,
                  currentAccount.user.id == account.user.id else { return }
            state = .ready(account)
        } catch {
            guard generation == accountLoadGeneration else { return }
            submissionError = accountError(from: error)
        }
    }

    func signOut() async {
        try? await authRepository.signOut()
        clearLocalAccount()
    }

    private func handle(_ event: AuthSessionEvent) async {
        switch event {
        case let .signedIn(user), let .tokenRefreshed(user):
            await loadAccount(for: user)
        case .signedOut:
            clearLocalAccount()
        }
    }

    private func loadAccount(for user: AuthenticatedUser) async {
        accountLoadGeneration += 1
        let generation = accountLoadGeneration
        lastUser = user
        state = .loadingAccount(user)

        for attempt in 0..<3 {
            do {
                async let profile = profileRepository.fetchProfile()
                async let wardrobe = wardrobeRepository.fetchDefaultWardrobe()
                let account = try await UserAccount(
                    user: user,
                    profile: profile,
                    defaultWardrobe: wardrobe
                )
                guard generation == accountLoadGeneration else { return }
                state = .ready(account)
                submissionError = nil
                return
            } catch {
                guard generation == accountLoadGeneration else { return }
                let accountError = accountError(from: error)
                guard accountError == .accountDataUnavailable else {
                    state = .failed(sessionFailure(from: accountError))
                    return
                }

                guard attempt < 2 else {
                    state = .failed(.accountDataUnavailable)
                    return
                }
                await sleep(attempt == 0 ? .milliseconds(100) : .milliseconds(250))
            }
        }
    }

    private func clearLocalAccount() {
        accountLoadGeneration += 1
        submissionGeneration += 1
        lastUser = nil
        state = .signedOut
        isSubmitting = false
        submissionError = nil
    }

    private func beginSubmission() -> Int {
        submissionGeneration += 1
        isSubmitting = true
        return submissionGeneration
    }

    private func finishSubmission(_ submission: Int) {
        guard submission == submissionGeneration else { return }
        isSubmitting = false
    }

    private func accountError(from error: any Error) -> AccountError {
        error as? AccountError ?? .unknown
    }

    private func sessionFailure(from error: AccountError) -> SessionFailure {
        switch error {
        case .accountDataUnavailable:
            .accountDataUnavailable
        case .networkUnavailable:
            .networkUnavailable
        default:
            .unknown
        }
    }
}
