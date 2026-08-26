import Foundation
import Supabase

struct SupabaseAuthRepository: AuthRepository {
    let client: SupabaseClient

    func sessionEvents() -> AsyncStream<AuthSessionEvent> {
        let authChanges = client.auth.authStateChanges
        return AsyncStream { continuation in
            let task = Task {
                for await (event, session) in authChanges {
                    if Task.isCancelled { break }
                    switch event {
                    case .signedOut, .userDeleted:
                        continuation.yield(.signedOut)
                    case .signedIn:
                        if let user = session?.user, let domainUser = Self.domainUser(from: user) {
                            continuation.yield(.signedIn(domainUser))
                        }
                    case .tokenRefreshed, .userUpdated:
                        if let user = session?.user, let domainUser = Self.domainUser(from: user) {
                            continuation.yield(.tokenRefreshed(domainUser))
                        }
                    case .initialSession, .passwordRecovery, .mfaChallengeVerified:
                        break
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func currentUser() async throws -> AuthenticatedUser? {
        do {
            let session = try await client.auth.session
            guard let user = Self.domainUser(from: session.user) else {
                throw AccountError.unknown
            }
            return user
        } catch AuthError.sessionMissing {
            return nil
        } catch {
            throw SupabaseErrorMapper.map(error)
        }
    }

    func signUp(email: String, password: String) async throws -> AuthenticatedUser {
        do {
            let response = try await client.auth.signUp(email: email, password: password)
            guard let user = Self.domainUser(from: response.user) else {
                throw AccountError.unknown
            }
            return user
        } catch {
            throw SupabaseErrorMapper.map(error)
        }
    }

    func signIn(email: String, password: String) async throws -> AuthenticatedUser {
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            guard let user = Self.domainUser(from: session.user) else {
                throw AccountError.unknown
            }
            return user
        } catch {
            throw SupabaseErrorMapper.map(error)
        }
    }

    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            throw SupabaseErrorMapper.map(error)
        }
    }

    private static func domainUser(from user: User) -> AuthenticatedUser? {
        guard let email = user.email else { return nil }
        return AuthenticatedUser(id: user.id, email: email)
    }
}
