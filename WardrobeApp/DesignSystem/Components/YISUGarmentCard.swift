import SwiftUI

enum YISUGarmentCardPolicy {
    static func canOpen(state: YISUGarmentCardState) -> Bool {
        state != .loading
    }
}

struct YISUGarmentCard: View {
    let item: GarmentSummary
    let state: YISUGarmentCardState
    let onSelect: (GarmentSummary) -> Void

    var body: some View {
        Button {
            guard YISUGarmentCardPolicy.canOpen(state: state) else { return }
            onSelect(item)
        } label: {
            VStack(alignment: .leading, spacing: YISUTheme.Spacing.sm) {
                imageArea
                    .frame(maxWidth: .infinity)
                    .frame(height: 154)
                    .background(imageBackground)
                    .clipShape(RoundedRectangle(cornerRadius: YISUTheme.Radius.medium))

                if state == .loading {
                    loadingLine(width: 116)
                    loadingLine(width: 86)
                } else {
                    Text(item.title)
                        .font(YISUTheme.Typography.headline)
                        .foregroundStyle(YISUTheme.Color.textPrimary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(item.metadata)
                        .font(YISUTheme.Typography.footnote)
                        .foregroundStyle(YISUTheme.Color.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .padding(YISUTheme.Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: 226, alignment: .topLeading)
            .background(YISUTheme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: YISUTheme.Radius.large))
            .shadow(color: YISUTheme.Shadow.color, radius: YISUTheme.Shadow.radius, y: YISUTheme.Shadow.y)
            .scaleEffect(state == .pressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .disabled(!YISUGarmentCardPolicy.canOpen(state: state))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("designSystem.garment.\(item.id)")
        .accessibilityLabel("\(item.title)，\(item.metadata)")
    }

    private var imageBackground: Color {
        switch item.imagePath {
        case "garment-white-linen-shirt": Color(red: 250 / 255, green: 238 / 255, blue: 240 / 255)
        case "garment-powder-blue-knit": Color(red: 232 / 255, green: 241 / 255, blue: 247 / 255)
        case "garment-beige-trench": YISUTheme.Color.surfaceSubtle
        case "garment-black-knit-dress": YISUTheme.Color.lavender
        default: YISUTheme.Color.surfaceSubtle
        }
    }

    @ViewBuilder
    private var imageArea: some View {
        switch state {
        case .loading:
            ProgressView()
                .tint(YISUTheme.Color.brandEmphasis)
        case .imageError:
            placeholder(symbol: "photo.badge.exclamationmark", label: "图片加载失败")
        case .normal, .pressed:
            if let imagePath = item.imagePath {
                Image(imagePath)
                    .resizable()
                    .scaledToFit()
                    .padding(YISUTheme.Spacing.sm)
                    .accessibilityHidden(true)
            } else {
                placeholder(symbol: "hanger", label: "暂无衣物图片")
            }
        }
    }

    private func placeholder(symbol: String, label: String) -> some View {
        VStack(spacing: YISUTheme.Spacing.sm) {
            Image(systemName: symbol)
                .font(.system(size: 30, weight: .light))
            Text(label)
                .font(YISUTheme.Typography.footnote)
        }
        .foregroundStyle(YISUTheme.Color.textSecondary)
    }

    private func loadingLine(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: YISUTheme.Radius.small)
            .fill(YISUTheme.Color.surfaceSubtle)
            .frame(width: width, height: 14)
            .accessibilityHidden(true)
    }
}
