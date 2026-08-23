import SwiftUI

struct YISUAgreementCheckbox: View {
    @Binding var isSelected: Bool
    let onTerms: () -> Void
    let onPrivacy: () -> Void

    var body: some View {
        HStack(spacing: YISUTheme.Spacing.xs) {
            Button {
                isSelected.toggle()
            } label: {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 24, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(isSelected ? YISUTheme.Color.brand : YISUTheme.Color.textSecondary)
            .accessibilityLabel("同意服务条款与隐私政策")
            .accessibilityValue(isSelected ? "已勾选" : "未勾选")
            .accessibilityIdentifier("auth.agreement")

            Text("我已阅读并同意")
                .foregroundStyle(YISUTheme.Color.textSecondary)

            Button("《服务条款》", action: onTerms)
                .accessibilityIdentifier("auth.terms")

            Text("和")
                .foregroundStyle(YISUTheme.Color.textSecondary)

            Button("《隐私政策》", action: onPrivacy)
                .accessibilityIdentifier("auth.privacy")
        }
        .font(YISUTheme.Typography.footnote)
        .tint(YISUTheme.Color.brand)
        .lineLimit(1)
        .minimumScaleFactor(0.82)
    }
}
