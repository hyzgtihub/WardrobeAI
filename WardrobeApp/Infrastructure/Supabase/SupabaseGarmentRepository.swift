import Foundation
import Supabase

struct SupabaseGarmentRepository: GarmentRepository {
    static let activeOrderColumn = "created_at"

    let client: SupabaseClient

    struct CreatePayload: Encodable, Equatable, Sendable {
        let input: NewGarment

        func encode(to encoder: Encoder) throws {
            try input.encode(to: encoder)
        }
    }

    struct UpdatePayload: Encodable, Equatable, Sendable {
        let changes: GarmentChanges

        func encode(to encoder: Encoder) throws {
            try changes.encode(to: encoder)
        }
    }

    func fetchGarments(wardrobeID: UUID) async throws -> [Garment] {
        do {
            let response = try await client
                .from("garments")
                .select()
                .eq("wardrobe_id", value: wardrobeID)
                .is("deleted_at", value: nil)
                .order(Self.activeOrderColumn, ascending: false)
                .execute()
            return try JSONDecoder.supabase.decode([Garment].self, from: response.data)
        } catch {
            throw SupabaseGarmentErrorMapper.map(error)
        }
    }

    func createGarment(_ input: NewGarment) async throws -> Garment {
        do {
            let response = try await client
                .from("garments")
                .insert(CreatePayload(input: input))
                .select()
                .single()
                .execute()
            return try JSONDecoder.supabase.decode(Garment.self, from: response.data)
        } catch {
            throw SupabaseGarmentErrorMapper.map(error)
        }
    }

    func fetchGarment(id: UUID) async throws -> Garment {
        do {
            let response = try await client
                .from("garments")
                .select()
                .eq("id", value: id)
                .is("deleted_at", value: nil)
                .single()
                .execute()
            return try JSONDecoder.supabase.decode(Garment.self, from: response.data)
        } catch {
            throw SupabaseGarmentErrorMapper.map(error)
        }
    }

    func updateGarment(id: UUID, changes: GarmentChanges) async throws -> Garment {
        do {
            let response = try await client
                .from("garments")
                .update(UpdatePayload(changes: changes))
                .eq("id", value: id)
                .select()
                .single()
                .execute()
            return try JSONDecoder.supabase.decode(Garment.self, from: response.data)
        } catch {
            throw SupabaseGarmentErrorMapper.map(error)
        }
    }

    func deleteGarment(id: UUID) async throws {
        do {
            try await client
                .from("garments")
                .delete()
                .eq("id", value: id)
                .execute()
        } catch {
            throw SupabaseGarmentErrorMapper.map(error)
        }
    }
}

enum SupabaseGarmentErrorMapper {
    static func map(_ error: any Error) -> GarmentRepositoryError {
        if let urlError = error as? URLError {
            return map(urlError)
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return map(URLError(URLError.Code(rawValue: nsError.code)))
        }

        if let postgrestError = error as? PostgrestError {
            return map(postgrestCode: postgrestError.code)
        }

        if let storageError = error as? StorageError,
           let statusCode = storageError.statusCode.flatMap(Int.init) {
            return map(statusCode: statusCode)
        }

        return .unknown
    }

    static func map(postgrestCode: String?) -> GarmentRepositoryError {
        switch postgrestCode {
        case "42501", "PGRST301": .permissionDenied
        case "PGRST116": .notFound
        default: .unknown
        }
    }

    static func map(statusCode: Int) -> GarmentRepositoryError {
        switch statusCode {
        case 401, 403: .permissionDenied
        case 404: .notFound
        default: .unknown
        }
    }

    private static func map(_ error: URLError) -> GarmentRepositoryError {
        switch error.code {
        case .notConnectedToInternet, .timedOut, .networkConnectionLost,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            .networkUnavailable
        default:
            .unknown
        }
    }
}
