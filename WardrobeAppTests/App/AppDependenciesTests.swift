import Testing
@testable import YISU

@MainActor
@Suite("App dependencies")
struct AppDependenciesTests {
    @Test
    func registrationFailureScenarioPublishesDuplicateEmail() async {
        let dependencies = AppDependencies.uiTest(
            arguments: ["-ui-auth-scenario", "registration-failure"]
        )

        await dependencies.sessionStore.restore()
        await dependencies.sessionStore.signUp(email: "mia@example.com", password: "password")

        #expect(dependencies.sessionStore.state == .signedOut)
        #expect(dependencies.sessionStore.submissionError == .emailAlreadyRegistered)
    }
}
