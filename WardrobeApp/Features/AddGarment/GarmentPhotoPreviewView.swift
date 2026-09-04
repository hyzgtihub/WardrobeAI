import SwiftUI
import UIKit

struct GarmentPhotoPreviewView: View {
    let photo: GarmentImage
    let onReselect: () -> Void
    let onUsePhoto: () -> Void

    var body: some View {
        VStack(spacing: YISUTheme.Spacing.lg) {
            Text("确认照片")
                .font(YISUTheme.Typography.title)
                .foregroundStyle(YISUTheme.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let image = UIImage(data: photo.data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 520)
                    .clipShape(RoundedRectangle(cornerRadius: YISUTheme.Radius.large))
                    .accessibilityLabel("已选择的衣物照片")
                    .accessibilityIdentifier("addGarment.photoPreview")
            }

            Spacer(minLength: 0)

            HStack(spacing: YISUTheme.Spacing.md) {
                YISUButton(
                    title: "重新选择",
                    style: .secondary,
                    state: .normal,
                    accessibilityIdentifier: "addGarment.reselectPhoto",
                    action: onReselect
                )
                YISUButton(
                    title: "使用这张照片",
                    style: .primary,
                    state: .normal,
                    accessibilityIdentifier: "addGarment.usePhoto",
                    action: onUsePhoto
                )
            }
        }
        .padding(YISUTheme.Spacing.lg)
        .background(YISUTheme.Color.background.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}
