import SwiftUI

struct SignUpView: View {
    let isSubmitting: Bool
    let error: AccountError?
    let passwordTextContentType: UITextContentType?
    let onBack: (() -> Void)?
    let onCreated: (_ email: String, _ password: String) async -> AccountError?

    @Environment(\.dismiss) private var dismiss
    @State private var email: String
    @State private var password: String
    @State private var confirmation: String
    @State private var agreementAccepted: Bool
    @State private var submissionState: AuthSubmissionState
    @State private var validationIssue: SignUpIssue?

    init(
        isSubmitting: Bool = false,
        error: AccountError? = nil,
        passwordTextContentType: UITextContentType? = .newPassword,
        initialState: AuthSubmissionState = .idle,
        initialEmail: String = "",
        initialPassword: String = "",
        initialConfirmation: String = "",
        agreementAccepted: Bool = true,
        validationIssue: SignUpIssue? = nil,
        onBack: (() -> Void)? = nil,
        onCreated: @escaping (_ email: String, _ password: String) async -> AccountError? = { _, _ in nil }
    ) {
        self.isSubmitting = isSubmitting
        self.error = error
        self.passwordTextContentType = passwordTextContentType
        self.onBack = onBack
        self.onCreated = onCreated
        _email = State(initialValue: initialEmail)
        _password = State(initialValue: initialPassword)
        _confirmation = State(initialValue: initialConfirmation)
        _agreementAccepted = State(initialValue: agreementAccepted)
        _submissionState = State(initialValue: initialState)
        _validationIssue = State(initialValue: validationIssue)
    }

    var body: some View {
        YISUAuthScaffold(showsBrandHeader: false) {
            VStack(alignment: .leading, spacing: YISUTheme.Spacing.lg) {
                Button {
                    if let onBack { onBack() } else { dismiss() }
                } label: {
                    Label("返回登录", systemImage: "chevron.left")
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(YISUTheme.Color.brandEmphasis)
                .accessibilityIdentifier("auth.signUp.back")

                VStack(alignment: .leading, spacing: YISUTheme.Spacing.xs) {
                    Text("创建账号")
                        .font(YISUTheme.Typography.largeTitle)
                        .foregroundStyle(YISUTheme.Color.textPrimary)
                        .accessibilityIdentifier("auth.signUp.title")
                    Text("开始建立专属于你的数字衣橱")
                        .font(YISUTheme.Typography.callout)
                        .foregroundStyle(YISUTheme.Color.textSecondary)
                }

                if let serviceMessage {
                    Label(serviceMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(YISUTheme.Typography.footnote)
                        .foregroundStyle(YISUTheme.Color.danger)
                        .padding(YISUTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(YISUTheme.Color.dangerSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: YISUTheme.Radius.small))
                        .accessibilityIdentifier("auth.error")
                }

                VStack(spacing: YISUTheme.Spacing.md) {
                    YISUAuthField(
                        label: "邮箱",
                        placeholder: "name@example.com",
                        systemImage: "envelope",
                        text: binding(for: $email),
                        errorMessage: emailError,
                        textContentType: .emailAddress,
                        keyboardType: .emailAddress,
                        accessibilityIdentifier: "auth.signUp.email"
                    )
                    YISUPasswordField(
                        label: "密码",
                        placeholder: "至少 8 位",
                        text: binding(for: $password),
                        errorMessage: passwordError,
                        textContentType: passwordTextContentType,
                        accessibilityIdentifier: "auth.signUp.password"
                    )
                    YISUPasswordField(
                        label: "确认密码",
                        placeholder: "再次输入密码",
                        text: binding(for: $confirmation),
                        errorMessage: confirmationError,
                        textContentType: passwordTextContentType,
                        accessibilityIdentifier: "auth.signUp.confirmation"
                    )
                }

                YISUAgreementCheckbox(
                    isSelected: binding(for: $agreementAccepted),
                    onTerms: {},
                    onPrivacy: {}
                )

                if validationIssue == .agreementRequired {
                    Label(SignUpIssue.agreementRequired.message, systemImage: "exclamationmark.circle.fill")
                        .font(YISUTheme.Typography.footnote)
                        .foregroundStyle(YISUTheme.Color.danger)
                }

                YISUButton(
                    title: "创建账号",
                    style: .primary,
                    state: buttonState,
                    accessibilityIdentifier: "auth.signUp.submit",
                    action: submit
                )
            }
            .padding(YISUTheme.Spacing.lg)
            .background(YISUTheme.Color.surface.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(color: YISUTheme.Shadow.color, radius: YISUTheme.Shadow.radius, y: YISUTheme.Shadow.y)
        }
        .navigationBarHidden(true)
    }

    private var buttonState: YISUControlState {
        isSubmitting || submissionState == .submitting ? .loading : .normal
    }

    private var emailError: String? {
        if validationIssue == .invalidEmail { return SignUpIssue.invalidEmail.message }
        if submissionState == .emailExists || error == .emailAlreadyRegistered { return "该邮箱已注册，请直接登录" }
        return nil
    }

    private var passwordError: String? {
        validationIssue == .passwordTooShort ? SignUpIssue.passwordTooShort.message : nil
    }

    private var confirmationError: String? {
        validationIssue == .passwordMismatch ? SignUpIssue.passwordMismatch.message : nil
    }

    private var serviceMessage: String? {
        if submissionState == .serviceFailure { return "服务暂时不可用，请稍后重试" }
        switch error {
        case .emailAlreadyRegistered: return "该邮箱已注册，请直接登录"
        case .networkUnavailable: return "网络连接不可用，请稍后重试"
        case .invalidCredentials, .accountDataUnavailable, .invalidConfiguration, .unknown:
            return "服务暂时不可用，请稍后重试"
        case nil: return nil
        }
    }

    private func binding<Value>(for source: Binding<Value>) -> Binding<Value> {
        Binding(get: { source.wrappedValue }) { value in
            source.wrappedValue = value
            validationIssue = nil
            submissionState = submissionState.recovered
        }
    }

    private func submit() {
        guard submissionState.allowsSubmission else { return }
        if let issue = AuthFormPolicy.signUpIssue(
            email: email,
            password: password,
            confirmation: confirmation,
            agreementAccepted: agreementAccepted
        ) {
            validationIssue = issue
            return
        }
        Task {
            let result = await onCreated(email, password)
            switch result {
            case .emailAlreadyRegistered:
                submissionState = .emailExists
            case .some:
                submissionState = .serviceFailure
            case nil:
                break
            }
        }
    }
}

#Preview("P02 · 默认") { NavigationStack { SignUpView() } }
#Preview("P02 · 密码不符合") {
    SignUpView(initialEmail: "mia@example.com", initialPassword: "123", validationIssue: .passwordTooShort)
}
#Preview("P02 · 邮箱已存在") {
    SignUpView(initialState: .emailExists, initialEmail: "mia@example.com", initialPassword: "password", initialConfirmation: "password")
}
#Preview("P02 · 提交中") {
    SignUpView(initialState: .submitting, initialEmail: "mia@example.com", initialPassword: "password", initialConfirmation: "password")
}
#Preview("P02 · 服务失败") {
    SignUpView(initialState: .serviceFailure, initialEmail: "mia@example.com", initialPassword: "password", initialConfirmation: "password")
}
#Preview("P02 · 未同意协议") {
    SignUpView(initialEmail: "mia@example.com", initialPassword: "password", initialConfirmation: "password", agreementAccepted: false, validationIssue: .agreementRequired)
}
