import Foundation
import Supabase

struct SupabaseWardrobeRepository: WardrobeRepository {
    let client: SupabaseClient

    func fetchDefaultWardrobe() async throws -> WardrobeIdentity {
        do {
            let response = try await client
                .from("wardrobes")
                .select()
                .eq("is_default", value: true)
                .single()
                .execute()
            return try JSONDecoder.supabase.decode(WardrobeIdentity.self, from: response.data)
        } catch {
            throw SupabaseErrorMapper.map(error)
        }
    }
}
