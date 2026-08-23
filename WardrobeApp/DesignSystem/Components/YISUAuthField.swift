import SwiftUI

struct YISUAuthField: View {
    let label: String
    let placeholder: String
    let systemImage: String?
    @Binding var text: String
    var errorMessage: String? = nil
    var textContentType: UITextContentType? = nil
    var keyboardType: UIKeyboardType = .default
    var accessibilityIdentifier: String? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: YISUTheme.Spacing.xs) {
            Text(label)
                .font(YISUTheme.Typography.footnote.weight(.semibold))
                .foregroundStyle(YISUTheme.Color.textPrimary)

            HStack(spacing: YISUTheme.Spacing.md) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .frame(width: 20, height: 20)
                        .foregroundStyle(YISUTheme.Color.textPlaceholder)
                        .accessibilityHidden(true)
                }

                TextField(placeholder, text: $text)
                    .font(YISUTheme.Typography.callout)
                    .foregroundStyle(YISUTheme.Color.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(textContentType)
                    .keyboardType(keyboardType)
                    .focused($isFocused)
            }
            .padding(.horizontal, YISUTheme.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(YISUTheme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(borderColor, lineWidth: errorMessage == nil ? 1 : 1.5)
            }
            .accessibilityIdentifier(accessibilityIdentifier ?? "")

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(YISUTheme.Typography.footnote)
                    .foregroundStyle(YISUTheme.Color.danger)
                    .accessibilityIdentifier("\(accessibilityIdentifier ?? "auth.field").error")
            }
        }
    }

    private var borderColor: Color {
        if errorMessage != nil { return YISUTheme.Color.danger }
        return isFocused ? YISUTheme.Color.brand : YISUTheme.Color.border
    }
}

struct YISUPasswordField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var errorMessage: String? = nil
    var textContentType: UITextContentType? = .password
    var accessibilityIdentifier: String? = nil

    @State private var isVisible = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: YISUTheme.Spacing.xs) {
            Text(label)
                .font(YISUTheme.Typography.footnote.weight(.semibold))
                .foregroundStyle(YISUTheme.Color.textPrimary)

            HStack(spacing: YISUTheme.Spacing.md) {
                Image(systemName: "lock")
                    .frame(width: 20, height: 20)
                    .foregroundStyle(YISUTheme.Color.textPlaceholder)
                    .accessibilityHidden(true)

                Group {
                    if isVisible {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .font(YISUTheme.Typography.callout)
                .foregroundStyle(YISUTheme.Color.textPrimary)
                .textContentType(textContentType)
                .focused($isFocused)

                Button {
                    isVisible.toggle()
                } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(YISUTheme.Color.textSecondary)
                .accessibilityLabel(isVisible ? "隐藏密码" : "显示密码")
                .accessibilityIdentifier("\(accessibilityIdentifier ?? "auth.password").visibility")
            }
            .padding(.leading, YISUTheme.Spacing.md)
            .padding(.trailing, 6)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(YISUTheme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(borderColor, lineWidth: errorMessage == nil ? 1 : 1.5)
            }
            .accessibilityIdentifier(accessibilityIdentifier ?? "")

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(YISUTheme.Typography.footnote)
                    .foregroundStyle(YISUTheme.Color.danger)
            }
        }
    }

    private var borderColor: Color {
        if errorMessage != nil { return YISUTheme.Color.danger }
        return isFocused ? YISUTheme.Color.brand : YISUTheme.Color.border
    }
}
