import SwiftUI

struct SignInView: View {
    let isSubmitting: Bool
    let error: AccountError?
    let onRegister: (() -> Void)?
    let onForgotPassword: () -> Void
    let onSubmit: (_ email: String, _ password: String) async -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var agreementAccepted = true
    @State private var showsSignUp = false

    init(
        isSubmitting: Bool = false,
        error: AccountError? = nil,
        onRegister: (() -> Void)? = nil,
        onForgotPassword: @escaping () -> Void = {},
        onSubmit: @escaping (_ email: String, _ password: String) async -> Void = { _, _ in }
    ) {
        self.isSubmitting = isSubmitting
        self.error = error
        self.onRegister = onRegister
        self.onForgotPassword = onForgotPassword
        self.onSubmit = onSubmit
    }

    var body: some View {
        YISUAuthScaffold {
            VStack(spacing: YISUTheme.Spacing.lg) {
                VStack(spacing: YISUTheme.Spacing.xs) {
                    Text("欢迎回来")
                        .font(YISUTheme.Typography.title)
                        .foregroundStyle(YISUTheme.Color.textPrimary)
                    Text("登录后继续整理你的衣橱")
                        .font(YISUTheme.Typography.callout)
                        .foregroundStyle(YISUTheme.Color.textSecondary)
                }

                VStack(spacing: YISUTheme.Spacing.md) {
                    YISUAuthField(
                        label: "邮箱",
                        placeholder: "name@example.com",
                        systemImage: "envelope",
                        text: $email,
                        textContentType: .emailAddress,
                        keyboardType: .emailAddress,
                        accessibilityIdentifier: "auth.email"
                    )
                    YISUPasswordField(
                        label: "密码",
                        placeholder: "请输入密码",
                        text: $password,
                        accessibilityIdentifier: "auth.password"
                    )
                }

                HStack {
                    Spacer()
                    Button("忘记密码？", action: onForgotPassword)
                        .frame(minHeight: 44)
                        .font(YISUTheme.Typography.footnote.weight(.semibold))
                        .accessibilityIdentifier("auth.forgotPassword")
                }
                .tint(YISUTheme.Color.brandEmphasis)

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(YISUTheme.Typography.footnote)
                        .foregroundStyle(YISUTheme.Color.danger)
                        .padding(YISUTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(YISUTheme.Color.dangerSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: YISUTheme.Radius.small))
                        .accessibilityIdentifier("auth.error")
                }

                YISUButton(
                    title: "登录",
                    style: .primary,
                    state: isSubmitting ? .loading : (canSubmit ? .normal : .disabled),
                    accessibilityIdentifier: "auth.signIn"
                ) {
                    Task {
                        await onSubmit(email, password)
                    }
                }

                HStack(spacing: YISUTheme.Spacing.xs) {
                    Text("还没有账号？")
                        .foregroundStyle(YISUTheme.Color.textSecondary)
                    Button("立即注册") {
                        if let onRegister { onRegister() } else { showsSignUp = true }
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("auth.register")
                }
                .font(YISUTheme.Typography.callout)
                .tint(YISUTheme.Color.brandEmphasis)
                .frame(minHeight: 44)

                YISUAgreementCheckbox(
                    isSelected: $agreementAccepted,
                    onTerms: {},
                    onPrivacy: {}
                )
            }
            .padding(YISUTheme.Spacing.lg)
            .background(YISUTheme.Color.surface.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(color: YISUTheme.Shadow.color, radius: YISUTheme.Shadow.radius, y: YISUTheme.Shadow.y)
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showsSignUp) {
            SignUpView()
        }
    }

    private var canSubmit: Bool {
        AuthFormPolicy.canSignIn(email: email, password: password, agreementAccepted: agreementAccepted)
    }

    private var errorMessage: String? {
        switch error {
        case .invalidCredentials: "邮箱或密码不正确"
        case .networkUnavailable: "网络连接不可用，请稍后重试"
        case .emailAlreadyRegistered: "该邮箱已注册"
        case .accountDataUnavailable: "账号资料尚未准备完成，请重试"
        case .invalidConfiguration, .unknown: "服务暂时不可用，请稍后重试"
        case nil: nil
        }
    }
}

#Preview("P01 · 登录") {
    NavigationStack { SignInView() }
}
