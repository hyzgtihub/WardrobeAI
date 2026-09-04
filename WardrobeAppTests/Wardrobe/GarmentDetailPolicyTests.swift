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
