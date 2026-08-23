import SwiftUI

struct SignInView: View {
    let onRegister: (() -> Void)?
    let onForgotPassword: () -> Void
    let onSubmit: (_ email: String, _ password: String) -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var agreementAccepted = true
    @State private var showsSignUp = false

    init(
        onRegister: (() -> Void)? = nil,
        onForgotPassword: @escaping () -> Void = {},
        onSubmit: @escaping (_ email: String, _ password: String) -> Void = { _, _ in }
    ) {
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

                YISUButton(
                    title: "登录",
                    style: .primary,
                    state: canSubmit ? .normal : .disabled,
                    accessibilityIdentifier: "auth.signIn"
                ) {
                    onSubmit(email, password)
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
}

#Preview("P01 · 登录") {
    NavigationStack { SignInView() }
}
