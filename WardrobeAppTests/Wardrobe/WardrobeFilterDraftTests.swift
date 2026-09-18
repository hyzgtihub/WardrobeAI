import Testing
@testable import YISU

@Suite("Wardrobe filter draft")
struct WardrobeFilterDraftTests {
    @Test
    func initializationCopiesTheAppliedFilter() {
        let applied = WardrobeFilter(categories: [.tops], seasons: ["春季"], colors: ["白色"])

        let draft = WardrobeFilterDraft(applied)

        #expect(draft.filter == applied)
    }

    @Test
    func togglingOneDimensionDoesNotChangeOtherSelections() {
        let applied = WardrobeFilter(categories: [.tops], seasons: ["春季"], colors: ["白色"])
        var draft = WardrobeFilterDraft(applied)

        draft.toggle("夏季", in: .season)

        #expect(draft.filter.categories == [.tops])
        #expect(draft.filter.seasons == ["春季", "夏季"])
        #expect(draft.filter.colors == ["白色"])
        #expect(applied.seasons == ["春季"])
    }

    @Test
    func resettingDraftDoesNotMutateAppliedValue() {
        let applied = WardrobeFilter(seasons: ["春季"])
        var draft = WardrobeFilterDraft(applied)

        draft.reset()

        #expect(draft.filter.isEmpty)
        #expect(applied.seasons == ["春季"])
    }

    @Test
    func filterReflectsTogglesAcrossEveryDimension() {
        var draft = WardrobeFilterDraft(WardrobeFilter())

        draft.toggle("外套", in: .category)
        draft.toggle("秋季", in: .season)
        draft.toggle("黑色", in: .color)
        draft.toggle("羊毛", in: .material)
        draft.toggle("通勤", in: .style)
        draft.toggle("L", in: .size)
        draft.toggle("主衣橱", in: .storageLocation)

        #expect(draft.filter == WardrobeFilter(
            categories: [.outerwear],
            seasons: ["秋季"],
            colors: ["黑色"],
            materials: ["羊毛"],
            styles: ["通勤"],
            sizes: ["L"],
            storageLocations: ["主衣橱"]
        ))
    }
}
