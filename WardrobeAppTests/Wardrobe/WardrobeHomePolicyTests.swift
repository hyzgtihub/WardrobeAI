import Testing
@testable import YISU

@Suite("Wardrobe home policy")
struct WardrobeHomePolicyTests {
    @Test func allCategoryKeepsAcceptedOrder() {
        #expect(WardrobeHomePolicy.items(WardrobeSampleData.garments, matching: .all).map(\.title) == [
            "白色亚麻衬衫", "蓝色针织上衣", "米色风衣", "黑色针织连衣裙"
        ])
    }

    @Test func topsFilterKeepsTwoItems() {
        let result = WardrobeHomePolicy.items(WardrobeSampleData.garments, matching: .tops)
        #expect(result.map(\.title) == ["白色亚麻衬衫", "蓝色针织上衣"])
    }

    @Test func categoryWithoutItemsReturnsEmptyCollection() {
        #expect(WardrobeHomePolicy.items(WardrobeSampleData.garments, matching: .shoes).isEmpty)
    }
}
