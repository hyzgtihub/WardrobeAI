import Foundation
import Testing
@testable import YISU

@Suite("Wardrobe filter policy")
struct WardrobeFilterPolicyTests {
    @Test
    func emptyFilterHasNoActiveConditions() {
        let filter = WardrobeFilter()

        #expect(filter.isEmpty)
        #expect(filter.hasNonCategoryConditions == false)
        #expect(filter.activeNonCategoryCount == 0)
    }

    @Test
    func nonCategoryCountExcludesCategoriesAndAddsEveryOtherDimension() {
        let filter = WardrobeFilter(
            categories: [.tops, .pants],
            seasons: ["春季", "夏季"],
            colors: ["白色"],
            materials: ["Cotton"],
            styles: ["通勤"],
            sizes: ["M"],
            storageLocations: ["主衣橱"]
        )

        #expect(filter.hasNonCategoryConditions)
        #expect(filter.activeNonCategoryCount == 7)
        #expect(filter.isEmpty == false)
    }

    @Test
    func browseableCategoryOrderIsFrozen() {
        #expect(YISUCategory.browseableCases == [
            .tops, .pants, .dresses, .outerwear, .shoes, .bags, .accessories, .other
        ])
    }

    @Test
    func sameDimensionUsesOrAndDifferentDimensionsUseAnd() {
        var filter = WardrobeFilter()
        filter.colors = ["白色", "黑色"]
        filter.seasons = ["春季"]

        let result = WardrobeFilterPolicy.filteredGarments(Self.fixtures, by: filter)

        #expect(result.map(\.name) == ["白衬衫", "黑色春季外套"])
    }

    @Test
    func normalizationTrimsAndIgnoresEnglishCase() {
        #expect(
            WardrobeFilterPolicy.normalized("  Cotton ") ==
                WardrobeFilterPolicy.normalized("cotton")
        )
    }

    @Test
    func emptyDimensionDoesNotRestrictSelectedCategoriesOrChangeFixtureOrder() {
        var filter = WardrobeFilter()
        filter.categories = [.tops, .outerwear]
        filter.styles = []

        let result = WardrobeFilterPolicy.filteredGarments(Self.fixtures, by: filter)

        #expect(result.map(\.name) == ["白衬衫", "黑色春季外套"])
    }

    @Test
    func arraySelectionsMatchNormalizedIntersections() {
        var filter = WardrobeFilter()
        filter.materials = ["cotton"]

        let result = WardrobeFilterPolicy.filteredGarments(Self.fixtures, by: filter)

        #expect(result.map(\.name) == ["白衬衫", "蓝色长裤"])
    }

    @Test
    func optionalScalarSelectionsExcludeMissingValuesAndAcceptCustomValues() {
        var filter = WardrobeFilter()
        filter.sizes = ["M", "custom"]
        filter.storageLocations = ["客房衣柜"]

        let result = WardrobeFilterPolicy.filteredGarments(Self.fixtures, by: filter)

        #expect(result.map(\.name) == ["定制礼服"])
    }

    @Test
    func fixedCategoryAndSeasonOptionsKeepTheirDefinedOrderAndCounts() {
        #expect(WardrobeFilterPolicy.options(for: .category, in: Self.fixtures) == [
            .init(value: "上衣", count: 1), .init(value: "裤子", count: 1),
            .init(value: "连衣裙", count: 1), .init(value: "外套", count: 1),
            .init(value: "鞋履", count: 0), .init(value: "包袋", count: 0),
            .init(value: "配饰", count: 0), .init(value: "其他", count: 0)
        ])
        #expect(WardrobeFilterPolicy.options(for: .season, in: Self.fixtures) == [
            .init(value: "春季", count: 2), .init(value: "夏季", count: 2),
            .init(value: "秋季", count: 1), .init(value: "冬季", count: 0)
        ])
    }

    @Test
    func dynamicOptionsTrimDeduplicateAndKeepFirstDisplaySpelling() {
        let materialOptions = WardrobeFilterPolicy.options(for: .material, in: Self.fixtures)

        #expect(materialOptions == [
            .init(value: "Cotton", count: 2), .init(value: "Linen", count: 1),
            .init(value: "Silk", count: 1), .init(value: "Wool", count: 1)
        ])
    }

    @Test
    func dynamicOptionsIncludeCustomValuesAndOmitBlankValues() {
        let storageOptions = WardrobeFilterPolicy.options(for: .storageLocation, in: Self.fixtures)
        let colorOptions = WardrobeFilterPolicy.options(for: .color, in: Self.fixtures)

        #expect(storageOptions.contains(.init(value: "客房衣柜", count: 1)))
        #expect(colorOptions.contains(where: { $0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) == false)
    }

    @Test
    func categoryCountsIncludeEveryBrowseableCategoryAndExcludeAllPseudoCategory() {
        let counts = WardrobeFilterPolicy.categoryCounts(in: Self.fixtures)

        #expect(counts == [
            .tops: 1, .pants: 1, .dresses: 1, .outerwear: 1,
            .shoes: 0, .bags: 0, .accessories: 0, .other: 0
        ])
        #expect(counts[.all] == nil)
    }

    private static let fixtures = [
        garment(
            name: "白衬衫", category: .tops, seasons: ["春季", "夏季"], colors: ["白色", " "],
            materials: [" Cotton ", "Linen", " "], styles: ["通勤"], size: "M", storageLocation: "主衣橱"
        ),
        garment(
            name: "蓝色长裤", category: .pants, seasons: ["秋季"], colors: ["蓝色"],
            materials: ["cotton"], styles: ["Casual"], size: nil, storageLocation: nil
        ),
        garment(
            name: "黑色春季外套", category: .outerwear, seasons: ["春季"], colors: [" 黑色 "],
            materials: ["Wool"], styles: ["通勤"], size: "L", storageLocation: "主衣橱"
        ),
        garment(
            name: "定制礼服", category: .dresses, seasons: ["夏季"], colors: ["紫色"],
            materials: ["Silk"], styles: ["晚宴"], size: "Custom", storageLocation: "客房衣柜"
        )
    ]

    private static func garment(
        name: String,
        category: YISUCategory,
        seasons: [String],
        colors: [String],
        materials: [String],
        styles: [String],
        size: String?,
        storageLocation: String?
    ) -> Garment {
        Garment(
            id: UUID(), userID: UUID(), wardrobeID: UUID(), imagePath: "image.jpg", name: name,
            category: category, seasons: seasons, colors: colors, brand: nil, price: nil, size: size,
            purchaseDate: nil, materials: materials, styles: styles, storageLocation: storageLocation,
            notes: nil, createdAt: .distantPast, updatedAt: .distantPast, deletedAt: nil
        )
    }
}
