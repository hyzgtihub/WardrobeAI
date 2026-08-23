import Testing
@testable import YISU

@Suite("Auth submission state")
struct AuthSubmissionStateTests {
    @Test func submittingBlocksRepeatAction() {
        #expect(AuthSubmissionState.submitting.allowsSubmission == false)
    }

    @Test(arguments: [AuthSubmissionState.emailExists, .serviceFailure])
    func failuresCanReturnToIdle(_ state: AuthSubmissionState) {
        #expect(state.recovered == .idle)
    }
}
