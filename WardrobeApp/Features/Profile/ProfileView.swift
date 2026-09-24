import SwiftUI

struct ProfileView: View {
    let account: UserAccount
    let isSaving: Bool
    let onBack: () -> Void
    let onSave: (ProfileChanges) async -> Bool
    let onSignOut: () async -> Void

    @State private var isEditingNickname = false

    var body: some View {
        Group {
            if isEditingNickname {
                NicknameEditor(
                    nickname: account.profile.nickname,
                    onBack: { isEditingNickname = false },
                    onSave: { nickname in
                        await onSave(ProfileChanges(
                            nickname: nickname,
                            languageCode: account.profile.languageCode,
                            notificationsEnabled: account.profile.notificationsEnabled
                        ))
                    }
                )
            } else {
                VStack(spacing: 0) {
                    ProfileHeader(title: "我的", backLabel: "返回衣橱", identifier: "profile.back", onBack: onBack)
                    ScrollView {
                        VStack(spacing: 32) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 80, weight: .ultraLight))
                                .foregroundStyle(YISUTheme.Color.textSecondary)
                                .frame(width: 104, height: 104)
                                .background(YISUTheme.Color.lavender, in: Circle())
                                .accessibilityLabel("默认头像")
                                .padding(.vertical, 24)

                            VStack(spacing: 0) {
                                Button { isEditingNickname = true } label: {
                                    HStack {
                                        profileField("昵称", value: account.profile.nickname)
                                        Spacer(minLength: 16)
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(YISUTheme.Color.textSecondary)
                                            .accessibilityHidden(true)
                                    }
                                    .padding(.vertical, 20)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("profile.editNickname")
                                .accessibilityLabel("昵称，\(account.profile.nickname)")
                                Divider().overlay(YISUTheme.Color.border)
                                profileField("电子邮箱", value: account.user.email)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 20)
                            }

                            YISUButton(title: "退出登录", style: .secondary, state: isSaving ? .disabled : .normal, accessibilityIdentifier: "profile.signOut") {
                                Task { await onSignOut() }
                            }
                            .padding(.top, 32)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("profile.screen")
            }
        }
        .foregroundStyle(YISUTheme.Color.textPrimary)
        .background(YISUTheme.Color.surface.ignoresSafeArea())
        .navigationBarHidden(true)
        .id(account.user.id)
    }

    private func profileField(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline).foregroundStyle(YISUTheme.Color.textSecondary)
            Text(value).font(.body)
        }
    }
}

private struct NicknameEditor: View {
    let nickname: String
    let onBack: () -> Void
    let onSave: (String) async -> Bool

    @State private var draft: String
    @State private var isSubmitting = false
    @State private var saveFailed = false
    @FocusState private var isFocused: Bool

    init(nickname: String, onBack: @escaping () -> Void, onSave: @escaping (String) async -> Bool) {
        self.nickname = nickname
        self.onBack = onBack
        self.onSave = onSave
        _draft = State(initialValue: nickname)
    }

    private var trimmed: String { draft.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { (1...30).contains(trimmed.count) && trimmed != nickname }

    var body: some View {
        VStack(spacing: 0) {
            ProfileHeader(title: "昵称", backLabel: "返回个人资料", identifier: "profile.nicknameBack", onBack: onBack)
                .disabled(isSubmitting)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("请输入昵称").font(.largeTitle.bold()).padding(.top, 24)
                    HStack(spacing: 8) {
                        TextField("请输入昵称", text: $draft)
                            .font(.body)
                            .focused($isFocused)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit { submit() }
                            .accessibilityLabel("昵称")
                            .accessibilityIdentifier("profile.nickname")
                        if !draft.isEmpty {
                            Button {
                                draft = ""
                                isFocused = true
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(YISUTheme.Color.textSecondary)
                                    .frame(width: 44, height: 44)
                            }
                            .accessibilityLabel("清空昵称")
                            .accessibilityIdentifier("profile.clearNickname")
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 4)
                    .frame(minHeight: 56)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(YISUTheme.Color.border))
                    .disabled(isSubmitting)
                    Text("昵称须为 1～30 个字符，支持中文。")
                        .font(.footnote)
                        .foregroundStyle(YISUTheme.Color.textSecondary)
                    if trimmed.count > 30 {
                        Text("昵称不能超过 30 个字符")
                            .font(.footnote).foregroundStyle(YISUTheme.Color.danger)
                    }
                    if saveFailed {
                        Text("保存失败，请稍后重试")
                            .font(.footnote).foregroundStyle(YISUTheme.Color.danger)
                            .accessibilityIdentifier("profile.saveError")
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .safeAreaInset(edge: .bottom) {
            YISUButton(title: "完成", style: .primary,
                       state: isSubmitting ? .loading : (canSave ? .normal : .disabled),
                       accessibilityIdentifier: "profile.save", action: submit)
                .padding(24)
                .background(YISUTheme.Color.surface)
        }
        .task { isFocused = true }
        .onChange(of: draft) { _, _ in saveFailed = false }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("profile.nicknameEditor")
    }

    private func submit() {
        guard canSave, !isSubmitting else { return }
        let value = trimmed
        isSubmitting = true
        saveFailed = false
        Task { @MainActor in
            let saved = await onSave(value)
            isSubmitting = false
            if saved {
                isFocused = false
                onBack()
            } else {
                saveFailed = true
            }
        }
    }
}

private struct ProfileHeader: View {
    let title: String
    let backLabel: String
    let identifier: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(backLabel)
            .accessibilityIdentifier(identifier)
            Spacer()
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            Spacer()
            Color.clear.frame(width: 44, height: 44).accessibilityHidden(true)
        }
        .padding(.horizontal, 12)
    }
}
