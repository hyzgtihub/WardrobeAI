import Foundation
import Supabase

struct SupabaseProfileRepository: ProfileRepository {
    let client: SupabaseClient

    func fetchProfile() async throws -> UserProfile {
        do {
            let response = try await client
                .from("profiles")
                .select()
                .single()
                .execute()
            return try JSONDecoder.supabase.decode(UserProfile.self, from: response.data)
        } catch {
            throw SupabaseErrorMapper.map(error)
        }
    }

    func updateProfile(_ changes: ProfileChanges, for userID: UUID) async throws -> UserProfile {
        do {
            let response = try await client
                .from("profiles")
                .update(changes)
                .eq("id", value: userID)
                .select()
                .single()
                .execute()
            return try JSONDecoder.supabase.decode(UserProfile.self, from: response.data)
        } catch {
#if DEBUG
            if let postgrestError = error as? PostgrestError {
                print("Profile update failed [\(postgrestError.code ?? "unknown")]")
            }
#endif
            throw SupabaseErrorMapper.map(error)
        }
    }
}
