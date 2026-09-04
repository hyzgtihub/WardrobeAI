import Foundation
import Observation

@MainActor
@Observable
final class GarmentStore {
    enum State: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failed
    }

    private(set) var state: State = .idle
    private(set) var garments: [Garment] = []

    private let repository: any GarmentRepository

    init(repository: any GarmentRepository) {
        self.repository = repository
    }

    func load(wardrobeID: UUID) async {
        guard state != .loading else { return }
        state = .loading
        do {
            garments = try await repository.fetchGarments(wardrobeID: wardrobeID)
            state = .loaded
        } catch {
            garments = []
            state = .failed
        }
    }

    func insertCreated(_ garment: Garment) {
        garments.removeAll { $0.id == garment.id }
        garments.insert(garment, at: 0)
        state = .loaded
    }

    func replacePersisted(_ garment: Garment) {
        guard let index = garments.firstIndex(where: { $0.id == garment.id }) else { return }
        garments[index] = garment
    }

    func removePersisted(id: UUID) {
        garments.removeAll { $0.id == id }
    }
}
