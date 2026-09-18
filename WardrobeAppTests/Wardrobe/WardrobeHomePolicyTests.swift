import Foundation
import Testing
@testable import YISU

@Suite("Wardrobe home policy")
struct WardrobeHomePolicyTests {
    @Test
    func selectingOneCategoryReplacesCategoriesAndPreservesOtherDimensions() {
        var filter = WardrobeFilter(categories: [.pants, .dresses], seasons: ["夏季"])

        filter.categories = WardrobeCategorySelection.replacing(filter.categories, with: .tops)

        #expect(filter.categories == [.tops])
        #expect(filter.seasons == ["夏季"])
        #expect(WardrobeFilterPolicy.filteredGarments(Self.fixtures, by: filter).map(\.name) == ["夏季上衣"])
    }

    @Test
    func multipleCategoriesDisplayTheirCombinedGarmentsInSourceOrder() {
        let filter = WardrobeFilter(categories: [.tops, .outerwear])

        let result = WardrobeFilterPolicy.filteredGarments(Self.fixtures, by: filter)

        #expect(filter.categories.count == 2)
        #expect(result.map(\.name) == ["夏季上衣", "秋季外套"])
    }

    @Test
    func clearingAllRestoresEveryGarmentInSourceOrder() {
        var filter = WardrobeFilter(categories: [.tops], seasons: ["冬季"])
        #expect(WardrobeFilterPolicy.filteredGarments(Self.fixtures, by: filter).isEmpty)

        filter = WardrobeFilter()

        #expect(filter.isEmpty)
        #expect(WardrobeFilterPolicy.filteredGarments(Self.fixtures, by: filter).map(\.name) == [
            "夏季上衣", "秋季外套", "冬季长裤"
        ])
    }

    @Test
    func anOldSheetDraftCannotApplyAfterSwitchingAccounts() {
        let userA = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let userB = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let oldSheetDraft = WardrobeFilter(seasons: ["夏季"])
        var session = WardrobeFilterSession()

        session.prepare(for: userA)
        session.prepare(for: userB)
        session.apply(oldSheetDraft, for: userA)

        #expect(session.ownerUserID == userB)
        #expect(session.filter(for: userB).isEmpty)
    }

    @Test
    func preparingTheSameAccountPreservesItsAppliedFilter() {
        let userID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let applied = WardrobeFilter(categories: [.tops], seasons: ["夏季"])
        var session = WardrobeFilterSession()

        session.prepare(for: userID)
        session.apply(applied, for: userID)
        session.prepare(for: userID)

        #expect(session.filter(for: userID) == applied)
    }

    private static let fixtures = [
        garment(name: "夏季上衣", category: .tops, seasons: ["夏季"]),
        garment(name: "秋季外套", category: .outerwear, seasons: ["秋季"]),
        garment(name: "冬季长裤", category: .pants, seasons: ["冬季"])
    ]

    private static func garment(name: String, category: YISUCategory, seasons: [String]) -> Garment {
        Garment(
            id: UUID(), userID: UUID(), wardrobeID: UUID(), imagePath: "image.jpg", name: name,
            category: category, seasons: seasons, colors: [], brand: nil, price: nil, size: nil,
            purchaseDate: nil, materials: [], styles: [], storageLocation: nil, notes: nil,
            createdAt: .distantPast, updatedAt: .distantPast, deletedAt: nil
        )
    }
}
