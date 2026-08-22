import Testing
@testable import YISU

@Suite("Wardrobe setup state")
struct WardrobeSetupStateTests {
    @Test func failuresCanRetry() {
        #expect(WardrobeSetupState.creationFailed.allowsRetry)
        #expect(WardrobeSetupState.currentRoleFailed.allowsRetry)
        #expect(!WardrobeSetupState.creating.allowsRetry)
    }

    @Test func completedStatesCanContinue() {
        #expect(WardrobeSetupState.created.allowsContinue)
        #expect(WardrobeSetupState.currentRole.allowsContinue)
    }
}
