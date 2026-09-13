import SwiftUI

struct SignUpView: View {
    let isSubmitting: Bool
    let error: AccountError?
    let passwordTextContentType: UITextContentType?
    let onBack: (() -> Void)?
    let onRequestCode: (_ email: String, _ password: String) async -> AccountError?
    let onResendCode: (_ email: String) async -> AccountError?
    let onVerifyCode: (_ email: String, _ code: String) async -> AccountError?

    @Environment(\.dismiss) private var dismiss
    @State private var email: String
    @State private var password: String
    @State private var confirmation: String
    @State private var verificationCode = ""
    @State private var agreementAccepted: Bool
    @State private var submissionState: AuthSubmissionState
    @State private var validationIssue: SignUpIssue?
    @State private var verificationState: SignUpVerificationState = .idle
    @State private var verificationError: AccountError?
    @State private var operationGeneration = SignUpOperationGeneration()

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
        onRequestCode: @escaping (_ email: String, _ password: String) async -> AccountError? = { _, _ in nil },
        onResendCode: @escaping (_ email: String) async -> AccountError? = { _ in nil },
        onVerifyCode: @escaping (_ email: String, _ code: String) async -> AccountError? = { _, _ in nil }
    ) {
        self.isSubmitting = isSubmitting
        self.error = error
        self.passwordTextContentType = passwordTextContentType
        self.onBack = onBack
        self.onRequestCode = onRequestCode
        self.onResendCode = onResendCode
        self.onVerifyCode = onVerifyCode
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
                        text: emailBinding,
                        errorMessage: emailError,
                        textContentType: .emailAddress,
                        keyboardType: .emailAddress,
                        accessibilityIdentifier: "auth.signUp.email"
                    )
                    .disabled(verificationState.locksEmail)
                    YISUPasswordField(
                        label: "密码",
                        placeholder: "至少 8 位",
                        text: binding(for: $password),
                        errorMessage: passwordError,
                        textContentType: passwordTextContentType,
                        accessibilityIdentifier: "auth.signUp.password"
                    )
                    .disabled(verificationState.locksPasswords || submissionState.blocksRegistrationDetails)
                    YISUPasswordField(
                        label: "确认密码",
                        placeholder: "再次输入密码",
                        text: binding(for: $confirmation),
                        errorMessage: confirmationError,
                        textContentType: passwordTextContentType,
                        accessibilityIdentifier: "auth.signUp.confirmation"
                    )
                    .disabled(verificationState.locksPasswords || submissionState.blocksRegistrationDetails)

                    HStack(alignment: .bottom, spacing: YISUTheme.Spacing.sm) {
                        YISUAuthField(
                            label: "邮箱验证码",
                            placeholder: "请输入邮件验证码",
                            systemImage: nil,
                            text: $verificationCode,
                            errorMessage: verificationError == nil ? nil : "验证码无效或已过期，请重试",
                            textContentType: .oneTimeCode,
                            keyboardType: .numberPad,
                            accessibilityIdentifier: "auth.signUp.code"
                        )
                        .disabled(!verificationState.allowsVerification)

                        Button(codeButtonTitle, action: requestCode)
                            .font(YISUTheme.Typography.footnote)
                            .foregroundStyle(YISUTheme.Color.brandEmphasis)
                            .frame(minWidth: 92, minHeight: 44)
                            .disabled(
                                !verificationState.allowsCodeRequest ||
                                    submissionState.blocksRegistrationDetails ||
                                    isSubmitting
                            )
                            .accessibilityIdentifier("auth.signUp.requestCode")
                    }

                    if verificationState.allowsVerification {
                        Text("如果该邮箱尚未注册，验证码已发送；如果已经注册，请直接登录。")
                            .font(YISUTheme.Typography.footnote)
                            .foregroundStyle(YISUTheme.Color.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("auth.signUp.codeRequestNotice")
                    }
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
        .task(id: verificationState) {
            guard verificationState.secondsRemaining > 0 else { return }
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            verificationState.tick()
        }
    }

    private var buttonState: YISUControlState {
        isSubmitting || verificationState == .verifying ? .loading :
            (verificationState.allowsVerification && !verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .normal : .disabled)
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

    private var codeButtonTitle: String {
        if verificationState == .sending { return "发送中…" }
        let seconds = verificationState.secondsRemaining
        return seconds > 0 ? "重新发送 \(seconds)s" : (verificationState == .idle ? "获取验证码" : "重新发送")
    }

    private func binding<Value>(for source: Binding<Value>) -> Binding<Value> {
        Binding(get: { source.wrappedValue }) { value in
            source.wrappedValue = value
            validationIssue = nil
            submissionState = submissionState.recovered
        }
    }

    private var emailBinding: Binding<String> {
        Binding(get: { email }) { value in
            let didChange = value != email
            email = value
            validationIssue = nil
            submissionState = submissionState.recovered
            guard didChange else { return }
            verificationState.reset()
            verificationCode = ""
            verificationError = nil
            operationGeneration.invalidate()
        }
    }

    private func requestCode() {
        guard verificationState.allowsCodeRequest else { return }
        let isResend: Bool
        if case .codeSent = verificationState { isResend = true } else { isResend = false }
        if let issue = AuthFormPolicy.signUpIssue(
            email: email,
            password: password,
            confirmation: confirmation,
            agreementAccepted: agreementAccepted
        ) {
            validationIssue = issue
            return
        }
        verificationState = .sending
        let requestedEmail = email
        let requestedPassword = password
        let requestGeneration = operationGeneration.current
        Task {
            let result = isResend
                ? await onResendCode(requestedEmail)
                : await onRequestCode(requestedEmail, requestedPassword)
            guard operationGeneration.accepts(requestGeneration), email == requestedEmail else { return }
            switch result {
            case .emailAlreadyRegistered:
                submissionState = .emailExists
                verificationState = .idle
            case .some:
                submissionState = .serviceFailure
                verificationState = .idle
            case nil:
                verificationState = .codeSent(secondsRemaining: 60)
            }
        }
    }

    private func submit() {
        guard verificationState.allowsVerification else { return }
        let code = verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        verificationState = .verifying
        verificationError = nil
        let submittedEmail = email
        let verificationGeneration = operationGeneration.current
        Task {
            let result = await onVerifyCode(submittedEmail, code)
            guard operationGeneration.accepts(verificationGeneration), email == submittedEmail else { return }
            if let result {
                verificationError = result
                verificationState = .codeSent(secondsRemaining: 0)
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
