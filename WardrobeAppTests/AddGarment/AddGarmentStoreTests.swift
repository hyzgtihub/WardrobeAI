import Foundation
import Testing
@testable import YISU

@MainActor
@Suite("Add garment store")
struct AddGarmentStoreTests {
    @Test(arguments: [
        (AddGarmentDraft(), AddGarmentIssue.photoRequired),
        (AddGarmentDraft(photo: .fixture), AddGarmentIssue.nameRequired),
        (AddGarmentDraft(photo: .fixture, name: "衬衫"), AddGarmentIssue.categoryRequired),
        (AddGarmentDraft(photo: .fixture, name: "衬衫", category: .tops), AddGarmentIssue.seasonRequired),
        (AddGarmentDraft(photo: .fixture, name: "衬衫", category: .tops, seasons: ["spring"], price: "12.345"), AddGarmentIssue.invalidPrice),
    ])
    func reportsTheFirstValidationIssue(input: (AddGarmentDraft, AddGarmentIssue)) async {
        let repositories = Repositories()
        let store = repositories.makeStore(draft: input.0)

        #expect(await store.submit(account: .fixture) == nil)
        #expect(store.issue == input.1)
        #expect(store.state == .editing)
        #expect(await repositories.image.events.isEmpty)
        #expect(await repositories.garment.inputs.isEmpty)
    }

    @Test
    func parsesChineseDecimalAndTrimsSubmittedFields() async throws {
        let repositories = Repositories()
        var draft = AddGarmentDraft.validFixture
        draft.name = "  白衬衫  "
        draft.brand = "  衣序  "
        draft.price = "1,234.50"
        draft.notes = "   "
        let store = repositories.makeStore(draft: draft)

        let result = await store.submit(account: .fixture)
        let input = try #require(await repositories.garment.inputs.first)

        #expect(result?.name == "白衬衫")
        #expect(input.price == Decimal(string: "1234.50"))
        #expect(input.brand == "衣序")
        #expect(input.notes == nil)
    }

    @Test
    func suppressesDuplicateSubmitWhileUploading() async {
        let repositories = Repositories(blockUpload: true)
        let store = repositories.makeStore(draft: .validFixture)

        let first = Task { await store.submit(account: .fixture) }
        await repositories.image.waitUntilUploadStarts()
        let duplicate = await store.submit(account: .fixture)
        await repositories.image.releaseUpload()
        _ = await first.value

        #expect(duplicate == nil)
        #expect(await repositories.image.uploadCount == 1)
        #expect(await repositories.garment.inputs.count == 1)
    }

    @Test
    func uploadFailureDoesNotCreateGarmentAndPreservesDraft() async {
        let repositories = Repositories(uploadError: TestFailure.upload)
        let store = repositories.makeStore(draft: .validFixture)

        #expect(await store.submit(account: .fixture) == nil)
        #expect(store.state == .uploadFailed)
        #expect(store.draft == .validFixture)
        #expect(await repositories.garment.inputs.isEmpty)
    }

    @Test
    func createFailureCompensatesOnceAndPreservesDraft() async {
        let repositories = Repositories(createError: TestFailure.create)
        let store = repositories.makeStore(draft: .validFixture)

        #expect(await store.submit(account: .fixture) == nil)

        #expect(await repositories.image.events == [
            .upload("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/original.jpg"),
            .delete("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/original.jpg"),
        ])
        #expect(store.draft == .validFixture)
        #expect(store.state == .createFailed)
    }

    @Test
    func compensationFailureDoesNotReplaceCreateFailure() async {
        let repositories = Repositories(
            createError: TestFailure.create,
            deleteError: TestFailure.delete
        )
        let store = repositories.makeStore(draft: .validFixture)

        #expect(await store.submit(account: .fixture) == nil)
        #expect(store.state == .createFailed)
        #expect(store.issue == nil)
        #expect(await repositories.image.deleteCount == 1)
    }

    @Test
    func successReturnsCreatedGarmentAndClearsIssue() async {
        let repositories = Repositories()
        let store = repositories.makeStore(draft: .validFixture)

        let garment = await store.submit(account: .fixture)

        #expect(garment?.id == UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"))
        #expect(garment?.imagePath == "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/original.jpg")
        #expect(store.state == .succeeded)
        #expect(store.issue == nil)
        #expect(await repositories.image.uploadCount == 1)
        #expect(await repositories.garment.inputs.count == 1)
    }
}

private struct Repositories {
    let garment: RecordingGarmentRepository
    let image: RecordingImageRepository

    init(
        uploadError: (any Error)? = nil,
        createError: (any Error)? = nil,
        deleteError: (any Error)? = nil,
        blockUpload: Bool = false
    ) {
        garment = RecordingGarmentRepository(error: createError)
        image = RecordingImageRepository(
            uploadError: uploadError,
            deleteError: deleteError,
            blockUpload: blockUpload
        )
    }

    @MainActor
    func makeStore(draft: AddGarmentDraft) -> AddGarmentStore {
        AddGarmentStore(
            garmentRepository: garment,
            imageRepository: image,
            draft: draft,
            makeID: { UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")! }
        )
    }
}

private actor RecordingGarmentRepository: GarmentRepository {
    private(set) var inputs: [NewGarment] = []
    private let error: (any Error)?

    init(error: (any Error)?) {
        self.error = error
    }

    func fetchGarments(wardrobeID: UUID) async throws -> [Garment] { [] }

    func createGarment(_ input: NewGarment) async throws -> Garment {
        inputs.append(input)
        if let error { throw error }
        return Garment(input: input)
    }
}

private actor RecordingImageRepository: GarmentImageRepository {
    enum Event: Equatable { case upload(String), delete(String) }

    private(set) var events: [Event] = []
    private let uploadError: (any Error)?
    private let deleteError: (any Error)?
    private let blockUpload: Bool
    private var uploadStartedContinuation: CheckedContinuation<Void, Never>?
    private var uploadReleaseContinuation: CheckedContinuation<Void, Never>?

    var uploadCount: Int { events.filter { if case .upload = $0 { true } else { false } }.count }
    var deleteCount: Int { events.filter { if case .delete = $0 { true } else { false } }.count }

    init(uploadError: (any Error)?, deleteError: (any Error)?, blockUpload: Bool) {
        self.uploadError = uploadError
        self.deleteError = deleteError
        self.blockUpload = blockUpload
    }

    func uploadJPEG(_ data: Data, path: String) async throws {
        events.append(.upload(path))
        if blockUpload {
            uploadStartedContinuation?.resume()
            uploadStartedContinuation = nil
            await withCheckedContinuation { uploadReleaseContinuation = $0 }
        }
        if let uploadError { throw uploadError }
    }

    func deleteImage(path: String) async throws {
        events.append(.delete(path))
        if let deleteError { throw deleteError }
    }

    func downloadImage(path: String) async throws -> Data { Data() }

    func waitUntilUploadStarts() async {
        if uploadCount > 0 { return }
        await withCheckedContinuation { uploadStartedContinuation = $0 }
    }

    func releaseUpload() {
        uploadReleaseContinuation?.resume()
        uploadReleaseContinuation = nil
    }
}

private enum TestFailure: Error { case upload, create, delete }

private extension GarmentImage {
    static let fixture = GarmentImage(data: Data([0xFF, 0xD8, 0xFF, 0xD9]), pixelSize: CGSize(width: 10, height: 10))
}

private extension AddGarmentDraft {
    static let validFixture = AddGarmentDraft(
        photo: .fixture,
        name: "白衬衫",
        category: .tops,
        seasons: ["spring"],
        colors: ["白色"],
        brand: "衣序",
        price: "199.90",
        size: "M",
        purchaseDate: Date(timeIntervalSince1970: 0),
        material: "棉",
        style: "通勤",
        storageLocation: "主衣柜",
        notes: "常穿"
    )
}

private extension UserAccount {
    static let fixture = UserAccount(
        user: AuthenticatedUser(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            email: "mia@example.com"
        ),
        profile: UserProfile(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            nickname: "Mia",
            avatarPath: nil,
            languageCode: "zh-CN",
            notificationsEnabled: true,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0)
        ),
        defaultWardrobe: WardrobeIdentity(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            ownerID: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            name: "我",
            isDefault: true
        )
    )
}

private extension Garment {
    init(input: NewGarment) {
        self.init(
            id: input.id,
            userID: input.userID,
            wardrobeID: input.wardrobeID,
            imagePath: input.imagePath,
            name: input.name,
            category: input.category,
            seasons: input.seasons,
            colors: input.colors,
            brand: input.brand,
            price: input.price,
            size: input.size,
            purchaseDate: input.purchaseDate,
            material: input.material,
            style: input.style,
            storageLocation: input.storageLocation,
            notes: input.notes,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            deletedAt: nil
        )
    }
}
