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
