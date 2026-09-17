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

    @Test func sentCodeLocksPasswordsButKeepsEmailEditableAndEnablesVerification() {
        let state = SignUpVerificationState.codeSent(secondsRemaining: 60)

        #expect(state.locksPasswords)
        #expect(!state.locksEmail)
        #expect(state.allowsVerification)
        #expect(!state.allowsCodeRequest)
    }

    @Test func sendingCodeLocksPasswordsButKeepsEmailEditable() {
        #expect(SignUpVerificationState.sending.locksPasswords)
        #expect(!SignUpVerificationState.sending.locksEmail)
    }

    @Test func verifyingLocksEmailUntilTheSubmittedCodeFinishes() {
        #expect(SignUpVerificationState.verifying.locksEmail)
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
        #expect(!state.locksPasswords)
    }

    @Test func registeredEmailBlocksRegistrationDetailsUntilEmailChanges() {
        #expect(AuthSubmissionState.emailExists.blocksRegistrationDetails)
        #expect(!AuthSubmissionState.idle.blocksRegistrationDetails)
    }

    @Test func editingEmailInvalidatesAnEarlierOperationEvenIfTheTextReturnsToItsOriginalValue() {
        var generation = SignUpOperationGeneration()
        let earlierOperation = generation.current

        generation.invalidate()
        generation.invalidate()

        #expect(!generation.accepts(earlierOperation))
        #expect(generation.accepts(generation.current))
    }
}
