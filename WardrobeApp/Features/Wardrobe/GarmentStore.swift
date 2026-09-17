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
    private var sessionOwner: SessionOwner?
    private var loadGeneration = 0

    init(repository: any GarmentRepository) {
        self.repository = repository
    }

    func prepareForSession(userID: UUID, wardrobeID: UUID) {
        let owner = SessionOwner(userID: userID, wardrobeID: wardrobeID)
        guard sessionOwner != owner else { return }
        sessionOwner = owner
        loadGeneration += 1
        garments = []
        state = .idle
    }

    func resetSession() {
        sessionOwner = nil
        loadGeneration += 1
        garments = []
        state = .idle
    }

    func garments(forUserID userID: UUID, wardrobeID: UUID) -> [Garment] {
        sessionOwner == SessionOwner(userID: userID, wardrobeID: wardrobeID) ? garments : []
    }

    func state(forUserID userID: UUID, wardrobeID: UUID) -> State {
        sessionOwner == SessionOwner(userID: userID, wardrobeID: wardrobeID) ? state : .idle
    }

    func load(userID: UUID, wardrobeID: UUID) async {
        let owner = SessionOwner(userID: userID, wardrobeID: wardrobeID)
        if sessionOwner == owner, state == .loading { return }
        prepareForSession(userID: userID, wardrobeID: wardrobeID)
        loadGeneration += 1
        let generation = loadGeneration
        state = .loading
        do {
            let loadedGarments = try await repository.fetchGarments(wardrobeID: wardrobeID)
            guard sessionOwner == owner, loadGeneration == generation else { return }
            garments = loadedGarments
            state = .loaded
        } catch {
            guard sessionOwner == owner, loadGeneration == generation else { return }
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

    private struct SessionOwner: Equatable {
        let userID: UUID
        let wardrobeID: UUID
    }
}
