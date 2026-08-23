import Foundation

enum SignUpIssue: Equatable, Sendable {
    case invalidEmail
    case passwordTooShort
    case passwordMismatch
    case agreementRequired

    var message: String {
        switch self {
        case .invalidEmail: "请输入有效邮箱"
        case .passwordTooShort: "密码至少 8 位"
        case .passwordMismatch: "两次输入的密码不一致"
        case .agreementRequired: "请先阅读并同意服务条款与隐私政策"
        }
    }
}

enum AuthFormPolicy {
    static func canSignIn(email: String, password: String, agreementAccepted: Bool) -> Bool {
        isValidEmail(email) && !password.isEmpty && agreementAccepted
    }

    static func signUpIssue(
        email: String,
        password: String,
        confirmation: String,
        agreementAccepted: Bool
    ) -> SignUpIssue? {
        if !isValidEmail(email) { return .invalidEmail }
        if password.count < 8 { return .passwordTooShort }
        if password != confirmation { return .passwordMismatch }
        if !agreementAccepted { return .agreementRequired }
        return nil
    }

    private static func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".")
    }
}
