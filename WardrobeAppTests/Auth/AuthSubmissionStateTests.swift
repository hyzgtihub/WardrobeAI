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

    @Test func sentCodeLocksCredentialsAndEnablesVerification() {
        let state = SignUpVerificationState.codeSent(secondsRemaining: 60)

        #expect(state.locksCredentials)
        #expect(state.allowsVerification)
        #expect(!state.allowsCodeRequest)
    }

    @Test func sendingCodeLocksCredentials() {
        #expect(SignUpVerificationState.sending.locksCredentials)
    }

    @Test func countdownEnablesResendAtZero() {
        var state = SignUpVerificationState.codeSent(secondsRemaining: 1)

        state.tick()

        #expect(state == .codeSent(secondsRemaining: 0))
        #expect(state.allowsCodeRequest)
    }

    @Test func changingEmailRestoresInitialState() {
        var state = SignUpVerificationState.codeSent(secondsRemaining: 42)

        state.reset()

        #expect(state == .idle)
        #expect(!state.locksCredentials)
    }
}
