import Testing
@testable import YISU

struct AuthFormPolicyTests {
    @Test("有效登录信息允许提交")
    func validSignInCanSubmit() {
        #expect(AuthFormPolicy.canSignIn(
            email: "mia@example.com",
            password: "password",
            agreementAccepted: true
        ))
    }

    @Test("缺少登录条件时禁止提交", arguments: [
        ("miaexample.com", "password", true),
        ("mia@example.com", "", true),
        ("mia@example.com", "password", false)
    ])
    func incompleteSignInCannotSubmit(email: String, password: String, accepted: Bool) {
        #expect(!AuthFormPolicy.canSignIn(
            email: email,
            password: password,
            agreementAccepted: accepted
        ))
    }

    @Test("注册校验按字段顺序返回明确问题", arguments: [
        ("miaexample.com", "password", "password", true, SignUpIssue.invalidEmail),
        ("mia@example.com", "short", "short", true, .passwordTooShort),
        ("mia@example.com", "password", "different", true, .passwordMismatch),
        ("mia@example.com", "password", "password", false, .agreementRequired)
    ])
    func signUpReturnsExpectedIssue(
        email: String,
        password: String,
        confirmation: String,
        accepted: Bool,
        expected: SignUpIssue
    ) {
        #expect(AuthFormPolicy.signUpIssue(
            email: email,
            password: password,
            confirmation: confirmation,
            agreementAccepted: accepted
        ) == expected)
        #expect(!expected.message.isEmpty)
    }

    @Test("有效注册信息没有校验问题")
    func validSignUpHasNoIssue() {
        #expect(AuthFormPolicy.signUpIssue(
            email: "mia@example.com",
            password: "password",
            confirmation: "password",
            agreementAccepted: true
        ) == nil)
    }
}
