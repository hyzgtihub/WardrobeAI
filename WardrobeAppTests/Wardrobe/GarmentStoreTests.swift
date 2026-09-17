import Foundation
import Testing
@testable import YISU

@MainActor
@Suite("Garment store")
struct GarmentStoreTests {
    @Test
    func loadForwardsWardrobeAndTransitionsToLoaded() async {
        let repository = ControlledGarmentRepository(result: .success([.fixture]), blocksFetch: true)
        let store = GarmentStore(repository: repository)
        let userID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let wardrobeID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        #expect(store.state == .idle)
        let load = Task { await store.load(userID: userID, wardrobeID: wardrobeID) }
        await repository.waitUntilFetchStarts()
        #expect(store.state == .loading)
        await repository.releaseFetch()
        await load.value

        #expect(store.state == .loaded)
        #expect(store.garments == [.fixture])
        #expect(await repository.requestedWardrobeIDs == [wardrobeID])
    }

    @Test
    func failedLoadClearsStaleItems() async {
        let repository = ControlledGarmentRepository(result: .failure(TestFailure.fetch))
        let store = GarmentStore(repository: repository)
        store.prepareForSession(
            userID: Garment.fixture.userID,
            wardrobeID: Garment.fixture.wardrobeID
        )
        store.insertCreated(.fixture)

        await store.load(userID: Garment.fixture.userID, wardrobeID: Garment.fixture.wardrobeID)

        #expect(store.state == .failed)
        #expect(store.garments.isEmpty)
    }

    @Test
    func switchingSessionsClearsDisplayedGarmentsAndRejectsThePreviousLateLoad() async {
        let userA = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let userB = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let wardrobeA = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let wardrobeB = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let garmentA = Garment.fixture(name: "A 的衬衫", userID: userA, wardrobeID: wardrobeA)
        let garmentB = Garment.fixture(name: "B 的外套", userID: userB, wardrobeID: wardrobeB)
        let repository = SwitchingGarmentRepository(
            results: [wardrobeA: [garmentA], wardrobeB: [garmentB]],
            blockedWardrobeID: wardrobeA
        )
        let store = GarmentStore(repository: repository)

        store.prepareForSession(userID: userA, wardrobeID: wardrobeA)
        store.insertCreated(garmentA)
        let loadA = Task { await store.load(userID: userA, wardrobeID: wardrobeA) }
        await repository.waitUntilBlockedFetchStarts()

        store.prepareForSession(userID: userB, wardrobeID: wardrobeB)

        #expect(store.state == .idle)
        #expect(store.garments.isEmpty)

        await store.load(userID: userB, wardrobeID: wardrobeB)
        #expect(store.state == .loaded)
        #expect(store.garments.map(\.name) == ["B 的外套"])

        await repository.releaseBlockedFetch()
        await loadA.value

        #expect(store.state == .loaded)
        #expect(store.garments.map(\.name) == ["B 的外套"])
        #expect(await repository.requestedWardrobeIDs == [wardrobeA, wardrobeB])
    }

    @Test
    func insertCreatedIsIdempotentAndPlacesNewestFirst() {
        let store = GarmentStore(repository: ControlledGarmentRepository(result: .success([])))
        let existing = Garment.fixture
        var replacement = Garment.fixture
        replacement.name = "更新后的衬衫"

        store.insertCreated(existing)
        store.insertCreated(replacement)

        #expect(store.garments.count == 1)
        #expect(store.garments.first?.name == "更新后的衬衫")
        #expect(store.state == .loaded)
    }

    @Test
    func garmentMapsAllPersistedFieldsToDetail() {
        let detail = GarmentDetailDraft(garment: .fixture)

        #expect(detail.id == UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"))
        #expect(detail.name == "白衬衫")
        #expect(detail.imagePath == "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/original.jpg")
        #expect(detail.category == .tops)
        #expect(detail.seasons == ["spring"])
        #expect(detail.colors == ["白色"])
        #expect(detail.brand == "衣序")
        #expect(detail.price == "¥199.90")
        #expect(detail.materials == ["棉"])
        #expect(detail.styles == ["通勤"])
    }
}

private actor ControlledGarmentRepository: GarmentRepository {
    private(set) var requestedWardrobeIDs: [UUID] = []
    private let result: Result<[Garment], any Error>
    private let blocksFetch: Bool
    private var startedContinuation: CheckedContinuation<Void, Never>?
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    init(result: Result<[Garment], any Error>, blocksFetch: Bool = false) {
        self.result = result
        self.blocksFetch = blocksFetch
    }

    func fetchGarments(wardrobeID: UUID) async throws -> [Garment] {
        requestedWardrobeIDs.append(wardrobeID)
        if blocksFetch {
            startedContinuation?.resume()
            startedContinuation = nil
            await withCheckedContinuation { releaseContinuation = $0 }
        }
        return try result.get()
    }

    func createGarment(_ input: NewGarment) async throws -> Garment { .fixture }

    func waitUntilFetchStarts() async {
        if !requestedWardrobeIDs.isEmpty { return }
        await withCheckedContinuation { startedContinuation = $0 }
    }

    func releaseFetch() {
        releaseContinuation?.resume()
        releaseContinuation = nil
    }
}

private actor SwitchingGarmentRepository: GarmentRepository {
    private(set) var requestedWardrobeIDs: [UUID] = []
    private let results: [UUID: [Garment]]
    private let blockedWardrobeID: UUID
    private var didStartBlockedFetch = false
    private var startedContinuation: CheckedContinuation<Void, Never>?
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    init(results: [UUID: [Garment]], blockedWardrobeID: UUID) {
        self.results = results
        self.blockedWardrobeID = blockedWardrobeID
    }

    func fetchGarments(wardrobeID: UUID) async throws -> [Garment] {
        requestedWardrobeIDs.append(wardrobeID)
        if wardrobeID == blockedWardrobeID {
            didStartBlockedFetch = true
            startedContinuation?.resume()
            startedContinuation = nil
            await withCheckedContinuation { releaseContinuation = $0 }
        }
        return results[wardrobeID, default: []]
    }

    func createGarment(_ input: NewGarment) async throws -> Garment { .fixture }

    func waitUntilBlockedFetchStarts() async {
        if didStartBlockedFetch { return }
        await withCheckedContinuation { startedContinuation = $0 }
    }

    func releaseBlockedFetch() {
        releaseContinuation?.resume()
        releaseContinuation = nil
    }
}

private enum TestFailure: Error { case fetch }

private extension Garment {
    static let fixture = Garment(
        id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
        userID: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
        wardrobeID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        imagePath: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/original.jpg",
        name: "白衬衫",
        category: .tops,
        seasons: ["spring"],
        colors: ["白色"],
        brand: "衣序",
        price: Decimal(string: "199.90"),
        size: "M",
        purchaseDate: Date(timeIntervalSince1970: 0),
        materials: ["棉"],
        styles: ["通勤"],
        storageLocation: "主衣柜",
        notes: "常穿",
        createdAt: Date(timeIntervalSince1970: 1),
        updatedAt: Date(timeIntervalSince1970: 1),
        deletedAt: nil
    )

    static func fixture(name: String, userID: UUID, wardrobeID: UUID) -> Garment {
        Garment(
            id: UUID(),
            userID: userID,
            wardrobeID: wardrobeID,
            imagePath: "fixture/original.jpg",
            name: name,
            category: .tops,
            seasons: ["spring"],
            colors: ["白色"],
            brand: "衣序",
            price: Decimal(string: "199.90"),
            size: "M",
            purchaseDate: Date(timeIntervalSince1970: 0),
            materials: ["棉"],
            styles: ["通勤"],
            storageLocation: "主衣柜",
            notes: nil,
            createdAt: Date(timeIntervalSince1970: 1),
            updatedAt: Date(timeIntervalSince1970: 1),
            deletedAt: nil
        )
    }
}
