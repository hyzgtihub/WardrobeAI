import Foundation
import Supabase

struct SupabaseGarmentImageRepository: GarmentImageRepository {
    static let bucket = "garment-images"

    let client: SupabaseClient

    func uploadJPEG(_ data: Data, path: String) async throws {
        do {
            try await client.storage
                .from(Self.bucket)
                .upload(
                    path,
                    data: data,
                    options: FileOptions(contentType: "image/jpeg", upsert: false)
                )
        } catch {
            throw SupabaseGarmentErrorMapper.map(error)
        }
    }

    func deleteImage(path: String) async throws {
        do {
            try await client.storage.from(Self.bucket).remove(paths: [path])
        } catch {
            throw SupabaseGarmentErrorMapper.map(error)
        }
    }

    func downloadImage(path: String) async throws -> Data {
        do {
            return try await client.storage.from(Self.bucket).download(path: path)
        } catch {
            throw SupabaseGarmentErrorMapper.map(error)
        }
    }
}
