import Foundation
import Testing
@testable import YISU

@Suite("Garment detail policy")
struct GarmentDetailPolicyTests {
    @Test func acceptedSampleIsValid() {
        #expect(GarmentDetailPolicy.issue(for: .whiteLinenShirt) == nil)
    }

    @Test func emptyRequiredFieldsAreRejected() {
        var draft = GarmentDetailDraft.whiteLinenShirt
        draft.name = "   "
        #expect(GarmentDetailPolicy.issue(for: draft) == .nameRequired)

        draft.name = "白色亚麻衬衫"
        draft.seasons = []
        #expect(GarmentDetailPolicy.issue(for: draft) == .seasonRequired)
    }

    @Test func textAutosaveUsesAcceptedDelay() {
        #expect(GarmentDetailPolicy.textDebounceNanoseconds == 800_000_000)
    }

    @Test(arguments: [
        GarmentAutosaveState.pending,
        .saving,
        .saved,
        .failed,
        .offline,
        .photoFailed,
        .loadingFailed
    ])
    func visibleStatesProvideStatusText(_ state: GarmentAutosaveState) {
        #expect(state.message.isEmpty == false)
    }
}

@Suite("Garment field selection policy")
struct GarmentFieldSelectionPolicyTests {
    @Test func frozenOptionsRemainInProductOrder() {
        #expect(GarmentFieldOptions.categories.map(\.title) == ["上衣", "裤子", "连衣裙", "外套", "鞋履", "包袋", "配饰", "其他"])
        #expect(GarmentFieldOptions.seasons == ["春季", "夏季", "秋季", "冬季"])
        #expect(GarmentFieldOptions.colors.first == "黑色系")
        #expect(GarmentFieldOptions.colors.last == "其他")
        #expect(GarmentFieldOptions.materials.last == "其他")
        #expect(GarmentFieldOptions.styles.last == "其他")
    }

    @Test func customValuesAreTrimmedDeduplicatedAndLengthLimited() {
        #expect(GarmentFieldSelectionPolicy.normalized(["棉", " 棉 ", "Silk", "silk", "", String(repeating: "a", count: 21)]) == ["棉", "Silk"])
    }

    @Test func allSeasonsUseCompactSummary() {
        #expect(GarmentFieldSelectionPolicy.summary(GarmentFieldOptions.seasons, kind: .season) == "四季")
        #expect(GarmentFieldSelectionPolicy.summary(["春季", "秋季"], kind: .season) == "春季、秋季")
    }

    @Test func categoryChangeExplainsWhenSizeMustBeCleared() {
        #expect(GarmentFieldSelectionPolicy.sizeDecision(from: .tops, to: .outerwear, currentSize: "M") == .keep)
        #expect(GarmentFieldSelectionPolicy.sizeDecision(from: .tops, to: .shoes, currentSize: "M") == .confirmClear)
        #expect(GarmentFieldSelectionPolicy.sizeDecision(from: .shoes, to: .accessories, currentSize: "38") == .confirmClear)
        #expect(GarmentFieldSelectionPolicy.sizeDecision(from: .tops, to: .shoes, currentSize: "") == .clearWithoutConfirmation)
    }
}

@Suite("Purchase date calendar")
struct PurchaseDateCalendarTests {
    @Test func monthGridIsMondayFirstAndAlwaysSixRows() throws {
        let model = PurchaseDateCalendar(today: Self.date(2026, 9, 5), displayedMonth: Self.date(2026, 9, 1))
        #expect(model.cells.count == 42)
        #expect(Self.day(model.cells[0].date) == (2026, 8, 31))
        #expect(Self.day(model.cells[41].date) == (2026, 10, 11))
    }

    @Test func pastAdjacentCellsSelectAndFutureCellsDisable() throws {
        let model = PurchaseDateCalendar(today: Self.date(2026, 9, 5), displayedMonth: Self.date(2026, 9, 1))
        #expect(model.cells.first?.isSelectable == true)
        #expect(model.cells.first?.isInDisplayedMonth == false)
        #expect(model.cells.first(where: { Self.day($0.date) == (2026, 9, 6) })?.isSelectable == false)
        #expect(model.canMoveToNextMonth == false)
    }

    @Test func existingDateControlsInitialFocusAndClearIsExplicit() {
        let existing = Self.date(2025, 12, 8)
        #expect(PurchaseDateCalendar.initialMonth(existingDate: existing, today: Self.date(2026, 9, 5)) == Self.date(2025, 12, 1))
        #expect(PurchaseDateCalendar.clearedSelection == nil)
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private static func day(_ date: Date) -> (Int, Int, Int) {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let value = calendar.dateComponents([.year, .month, .day], from: date)
        return (value.year!, value.month!, value.day!)
    }
}

@MainActor
@Suite("Garment detail autosave store")
struct GarmentDetailStoreTests {
    @Test func selectionCommitsRepositoryPatchAndPublishesPersistedGarment() async {
        let repository = DetailRecordingRepository(garment: .detailFixture)
        var published: Garment?
        let store = GarmentDetailStore(garment: .detailFixture, repository: repository, debounceNanoseconds: 1) { published = $0 }

        store.setColors(["蓝色系", "白色系"])
        await store.waitForSaves()

        #expect(await repository.changes.count == 1)
        #expect(published?.colors == ["蓝色系", "白色系"])
        #expect(store.state == .saved)
    }

    @Test func textEditDebouncesAndBlurFlushesImmediately() async {
        let repository = DetailRecordingRepository(garment: .detailFixture)
        let store = GarmentDetailStore(garment: .detailFixture, repository: repository, debounceNanoseconds: 5_000_000_000)
        store.editName("新名称")
        #expect(store.state == .pending)
        #expect(await repository.changes.isEmpty)

        await store.flush(.name)

        #expect(await repository.changes.count == 1)
        #expect(store.state == .saved)
    }

    @Test func invalidNameNeverTouchesRepository() async {
        let repository = DetailRecordingRepository(garment: .detailFixture)
        let store = GarmentDetailStore(garment: .detailFixture, repository: repository, debounceNanoseconds: 1)
        store.editName("   ")
        await store.waitForSaves()
        #expect(store.state == .failed)
        #expect(await repository.changes.isEmpty)
    }

    @Test func unchangedValueDoesNotTouchRepository() async {
        let repository = DetailRecordingRepository(garment: .detailFixture)
        let store = GarmentDetailStore(garment: .detailFixture, repository: repository, debounceNanoseconds: 1)
        store.setColors(["白色系"])
        await store.waitForSaves()
        #expect(await repository.changes.isEmpty)
    }

    @Test func categoryAndSizeShareOneSerializedLogicalPatch() async {
        let repository = DetailRecordingRepository(garment: .detailFixture)
        let store = GarmentDetailStore(garment: .detailFixture, repository: repository, debounceNanoseconds: 1)
        store.setCategory(.shoes, clearSize: true)
        await store.waitForSaves()
        #expect(await repository.changes == [GarmentChanges(category: .shoes, size: .clear)])
    }

    @Test func photoReplacementUploadsRevisionPatchesThenCleansOldObject() async throws {
        let repository = DetailRecordingRepository(garment: .detailFixture)
        let images = DetailRecordingImageRepository()
        let revision = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let store = GarmentDetailStore(garment: .detailFixture, repository: repository, imageRepository: images, makeRevisionID: { revision })

        await store.replacePhoto(data: Self.fixture("garment-photo-metadata"))

        let expected = GarmentImage.revisionPath(userID: Garment.detailUserID, garmentID: Garment.detailFixture.id, revisionID: revision)
        #expect(await images.uploadedPaths == [expected])
        #expect(await repository.changes.last?.imagePath == expected)
        #expect(await images.deletedPaths == ["old.jpg"])
        #expect(store.draft.imagePath == expected)
    }

    @Test func failedPhotoPatchCompensatesByDeletingNewObject() async {
        let repository = DetailRecordingRepository(garment: .detailFixture, updateError: DetailTestError.failed)
        let images = DetailRecordingImageRepository()
        let revision = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let store = GarmentDetailStore(garment: .detailFixture, repository: repository, imageRepository: images, makeRevisionID: { revision })

        await store.replacePhoto(data: Self.fixture("garment-photo-metadata"))

        let expected = GarmentImage.revisionPath(userID: Garment.detailUserID, garmentID: Garment.detailFixture.id, revisionID: revision)
        #expect(await images.deletedPaths == [expected])
        #expect(store.draft.imagePath == "old.jpg")
        #expect(store.state == .photoFailed)
    }

    @Test func deleteOnlyReportsSuccessAfterRepositoryDeletion() async {
        let repository = DetailRecordingRepository(garment: .detailFixture)
        let images = DetailRecordingImageRepository()
        let store = GarmentDetailStore(garment: .detailFixture, repository: repository, imageRepository: images)
        #expect(await store.delete())
        #expect(await repository.deletedIDs == [Garment.detailFixture.id])
        #expect(await images.deletedPaths == ["old.jpg"])
    }

    private static func fixture(_ name: String) -> Data {
        let url = Bundle(for: DetailFixtureBundleToken.self).url(forResource: name, withExtension: "jpg")!
        return try! Data(contentsOf: url)
    }
}

private actor DetailRecordingRepository: GarmentRepository {
    private var garment: Garment
    private(set) var changes: [GarmentChanges] = []
    private(set) var deletedIDs: [UUID] = []
    private let updateError: Error?
    init(garment: Garment, updateError: Error? = nil) { self.garment = garment; self.updateError = updateError }
    func fetchGarments(wardrobeID: UUID) async throws -> [Garment] { [garment] }
    func createGarment(_ input: NewGarment) async throws -> Garment { garment }
    func updateGarment(id: UUID, changes: GarmentChanges) async throws -> Garment {
        self.changes.append(changes)
        if let updateError { throw updateError }
        if let imagePath = changes.imagePath { garment.imagePath = imagePath }
        if let name = changes.name { garment.name = name }
        if let category = changes.category { garment.category = category }
        if let colors = changes.colors { garment.colors = colors }
        if let size = changes.size { switch size { case .value(let value): garment.size = value; case .clear: garment.size = nil } }
        garment.updatedAt = Date()
        return garment
    }
    func deleteGarment(id: UUID) async throws { deletedIDs.append(id) }
}

private actor DetailRecordingImageRepository: GarmentImageRepository {
    private(set) var uploadedPaths: [String] = []
    private(set) var deletedPaths: [String] = []
    func uploadJPEG(_ data: Data, path: String) async throws { uploadedPaths.append(path) }
    func deleteImage(path: String) async throws { deletedPaths.append(path) }
    func downloadImage(path: String) async throws -> Data { Data() }
}

private enum DetailTestError: Error { case failed }
private final class DetailFixtureBundleToken {}

private extension Garment {
    static let detailUserID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
    static let detailFixture = Garment(
        id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
        userID: detailUserID,
        wardrobeID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        imagePath: "old.jpg", name: "白衬衫", category: .tops, seasons: ["春季"], colors: ["白色系"],
        brand: nil, price: nil, size: "M", purchaseDate: nil, materials: ["棉"], styles: ["通勤"],
        storageLocation: nil, notes: nil, createdAt: Date(timeIntervalSince1970: 0), updatedAt: Date(timeIntervalSince1970: 0), deletedAt: nil
    )
}
