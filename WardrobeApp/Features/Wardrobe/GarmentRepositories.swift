import Foundation

protocol GarmentRepository: Sendable {
    func fetchGarments(wardrobeID: UUID) async throws -> [Garment]
    func createGarment(_ input: NewGarment) async throws -> Garment
}

protocol GarmentImageRepository: Sendable {
    func uploadJPEG(_ data: Data, path: String) async throws
    func deleteImage(path: String) async throws
    func downloadImage(path: String) async throws -> Data
}
