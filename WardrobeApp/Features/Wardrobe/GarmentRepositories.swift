import Foundation

enum GarmentRepositoryError: Error, Equatable, Sendable {
    case networkUnavailable
    case permissionDenied
    case notFound
    case unknown
}

protocol GarmentRepository: Sendable {
    func fetchGarments(wardrobeID: UUID) async throws -> [Garment]
    func createGarment(_ input: NewGarment) async throws -> Garment
}

protocol GarmentImageRepository: Sendable {
    func uploadJPEG(_ data: Data, path: String) async throws
    func deleteImage(path: String) async throws
    func downloadImage(path: String) async throws -> Data
}
