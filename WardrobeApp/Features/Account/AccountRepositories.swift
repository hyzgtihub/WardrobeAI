import Foundation

enum AuthSessionEvent: Equatable, Sendable {
    case signedIn(AuthenticatedUser)
    case signedOut
    case tokenRefreshed(AuthenticatedUser)
}

enum AccountError: Error, Equatable, Sendable {
    case invalidCredentials
    case emailAlreadyRegistered
    case networkUnavailable
    case accountDataUnavailable
    case invalidConfiguration
    case unknown
}

protocol AuthRepository: Sendable {
    func sessionEvents() -> AsyncStream<AuthSessionEvent>
    func currentUser() async throws -> AuthenticatedUser?
    func signUp(email: String, password: String) async throws -> AuthenticatedUser
    func signIn(email: String, password: String) async throws -> AuthenticatedUser
    func signOut() async throws
}

protocol ProfileRepository: Sendable {
    func fetchProfile() async throws -> UserProfile
    func updateProfile(_ changes: ProfileChanges, for userID: UUID) async throws -> UserProfile
}

protocol WardrobeRepository: Sendable {
    func fetchDefaultWardrobe() async throws -> WardrobeIdentity
}
