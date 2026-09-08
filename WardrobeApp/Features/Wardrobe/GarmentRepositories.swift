import Foundation

enum GarmentRepositoryError: Error, Equatable, Sendable {
    case networkUnavailable
    case permissionDenied
    case notFound
    case unknown
}

protocol GarmentRepository: Sendable {
    func fetchGarments(wardrobeID: UUID) async throws -> [Garment]
    func fetchGarment(id: UUID) async throws -> Garment
    func createGarment(_ input: NewGarment) async throws -> Garment
    func updateGarment(id: UUID, changes: GarmentChanges) async throws -> Garment
    func deleteGarment(id: UUID) async throws
}

extension GarmentRepository {
    func fetchGarment(id: UUID) async throws -> Garment { throw GarmentRepositoryError.notFound }
    func updateGarment(id: UUID, changes: GarmentChanges) async throws -> Garment {
        throw GarmentRepositoryError.unknown
    }
    func deleteGarment(id: UUID) async throws { throw GarmentRepositoryError.unknown }
}

protocol GarmentImageRepository: Sendable {
    func uploadJPEG(_ data: Data, path: String) async throws
    func deleteImage(path: String) async throws
    func downloadImage(path: String) async throws -> Data
}
