import PhotosUI
import SwiftUI

struct GarmentPhotoPickerView: View {
    let injectedPhotoData: Data?
    let onPhotoSelected: (Data) -> Void
    let onCancel: () -> Void

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: YISUTheme.Spacing.xl) {
            header
            Spacer()
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(YISUTheme.Color.brandEmphasis)
                .accessibilityHidden(true)
            VStack(spacing: YISUTheme.Spacing.sm) {
                Text("选择一张衣物照片")
                    .font(YISUTheme.Typography.title)
                    .foregroundStyle(YISUTheme.Color.textPrimary)
                Text("我们会自动修正方向、压缩图片并移除位置信息")
                    .font(YISUTheme.Typography.callout)
                    .foregroundStyle(YISUTheme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            photoControl
            Spacer()
        }
        .padding(YISUTheme.Spacing.lg)
        .background(YISUTheme.Color.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    onPhotoSelected(data)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("取消添加衣物")
            Spacer()
            Text("添加衣物")
                .font(YISUTheme.Typography.headline)
                .foregroundStyle(YISUTheme.Color.textPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
    }

    @ViewBuilder private var photoControl: some View {
        if let injectedPhotoData {
            YISUButton(
                title: "选择照片",
                style: .primary,
                state: .normal,
                accessibilityIdentifier: "addGarment.choosePhoto",
                action: { onPhotoSelected(injectedPhotoData) }
            )
        } else {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Text("选择照片")
                    .font(YISUTheme.Typography.headline)
                    .foregroundStyle(YISUTheme.Color.textOnBrand)
                    .frame(maxWidth: .infinity, minHeight: YISUTheme.Size.buttonHeight)
                    .background(YISUTheme.Color.brandEmphasis)
                    .clipShape(RoundedRectangle(cornerRadius: YISUTheme.Radius.medium))
            }
            .accessibilityIdentifier("addGarment.choosePhoto")
        }
    }
}
