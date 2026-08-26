import SwiftUI

struct ProfileView: View {
    let account: UserAccount
    let isSaving: Bool
    let error: AccountError?
    let onBack: () -> Void
    let onSave: (ProfileChanges) async -> Void
    let onSignOut: () async -> Void

    @State private var nickname: String

    init(
        account: UserAccount,
        isSaving: Bool,
        error: AccountError?,
        onBack: @escaping () -> Void,
        onSave: @escaping (ProfileChanges) async -> Void,
        onSignOut: @escaping () async -> Void
    ) {
        self.account = account
        self.isSaving = isSaving
        self.error = error
        self.onBack = onBack
        self.onSave = onSave
        self.onSignOut = onSignOut
        _nickname = State(initialValue: account.profile.nickname)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: YISUTheme.Spacing.lg) {
                HStack {
                    Button(action: onBack) {
                        Label("返回衣橱", systemImage: "chevron.left")
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(YISUTheme.Color.brandEmphasis)
                    Spacer()
                }

                Text("我的")
                    .font(YISUTheme.Typography.largeTitle)
                    .foregroundStyle(YISUTheme.Color.textPrimary)

                VStack(alignment: .leading, spacing: YISUTheme.Spacing.md) {
                    Text("邮箱")
                        .font(YISUTheme.Typography.footnote)
                        .foregroundStyle(YISUTheme.Color.textSecondary)
                    Text(account.user.email)
                        .font(YISUTheme.Typography.body)

                    TextField("昵称", text: $nickname)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("profile.nickname")

                    if error != nil {
                        Text("保存失败，请稍后重试")
                            .font(YISUTheme.Typography.footnote)
                            .foregroundStyle(YISUTheme.Color.danger)
                    }

                    YISUButton(
                        title: "保存昵称",
                        style: .primary,
                        state: saveState,
                        accessibilityIdentifier: "profile.save"
                    ) {
                        let value = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                        Task {
                            await onSave(ProfileChanges(
                                nickname: value,
                                languageCode: account.profile.languageCode,
                                notificationsEnabled: account.profile.notificationsEnabled
                            ))
                        }
                    }

                    YISUButton(
                        title: "退出登录",
                        style: .secondary,
                        state: .normal,
                        accessibilityIdentifier: "profile.signOut"
                    ) {
                        Task { await onSignOut() }
                    }
                }
                .padding(YISUTheme.Spacing.lg)
                .background(YISUTheme.Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: YISUTheme.Radius.large))
            }
            .padding(YISUTheme.Spacing.lg)
        }
        .background(YISUTheme.Color.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("profile.screen")
    }

    private var saveState: YISUControlState {
        let count = nickname.trimmingCharacters(in: .whitespacesAndNewlines).count
        if isSaving { return .loading }
        return (1...30).contains(count) ? .normal : .disabled
    }
}
