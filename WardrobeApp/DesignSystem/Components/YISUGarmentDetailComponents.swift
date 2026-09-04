import SwiftUI
import PhotosUI

struct YISUAutosaveStatus: View {
    let state: GarmentAutosaveState

    var body: some View {
        if state != .idle {
            Label(state.message, systemImage: icon)
                .font(YISUTheme.Typography.footnote.weight(.semibold))
                .foregroundStyle(color)
                .padding(.horizontal, 12)
                .frame(minHeight: 32)
                .background(.ultraThinMaterial, in: Capsule())
                .accessibilityIdentifier("garmentDetail.autosave")
        }
    }

    private var icon: String {
        switch state {
        case .pending: "clock"
        case .saving: "arrow.triangle.2.circlepath"
        case .saved: "checkmark"
        case .offline: "wifi.slash"
        case .failed, .photoFailed, .loadingFailed: "exclamationmark"
        case .idle: ""
        }
    }

    private var color: Color {
        switch state {
        case .failed, .photoFailed, .loadingFailed: YISUTheme.Color.danger
        default: YISUTheme.Color.navAccent
        }
    }
}

struct YISUEditableFieldRow: View {
    let title: String
    let value: String
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: YISUTheme.Spacing.md) {
                Text(title)
                    .foregroundStyle(YISUTheme.Color.textSecondary)
                Spacer()
                Text(value)
                    .foregroundStyle(YISUTheme.Color.textPrimary)
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(YISUTheme.Color.textPlaceholder)
            }
            .font(YISUTheme.Typography.callout)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}

struct YISUPhotoHero: View {
    let imageName: String
    let imageRepository: (any GarmentImageRepository)?
    let status: GarmentAutosaveState
    let onChangePhoto: () -> Void
    let photoSelection: Binding<PhotosPickerItem?>?

    init(
        imageName: String,
        imageRepository: (any GarmentImageRepository)? = nil,
        status: GarmentAutosaveState,
        onChangePhoto: @escaping () -> Void,
        photoSelection: Binding<PhotosPickerItem?>? = nil
    ) {
        self.imageName = imageName
        self.imageRepository = imageRepository
        self.status = status
        self.onChangePhoto = onChangePhoto
        self.photoSelection = photoSelection
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(red: 247 / 255, green: 233 / 255, blue: 236 / 255))
            if imageName.contains("/"), let imageRepository {
                PrivateGarmentImageView(path: imageName, repository: imageRepository)
                    .padding(26)
                    .accessibilityHidden(true)
            } else {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(26)
                    .accessibilityHidden(true)
            }
            VStack {
                HStack { YISUAutosaveStatus(state: status); Spacer() }
                Spacer()
                HStack {
                    Spacer()
                    if let photoSelection {
                        PhotosPicker(selection: photoSelection, matching: .images) { changePhotoLabel }
                            .simultaneousGesture(TapGesture().onEnded(onChangePhoto))
                            .accessibilityIdentifier("garmentDetail.changePhoto")
                    } else {
                        Button(action: onChangePhoto) { changePhotoLabel }
                            .accessibilityIdentifier("garmentDetail.changePhoto")
                    }
                }
            }
            .padding(16)
        }
        .frame(height: 300)
    }

    private var changePhotoLabel: some View {
        Text("换图")
            .font(YISUTheme.Typography.callout.weight(.semibold))
            .frame(width: 84, height: 44)
            .background(YISUTheme.Color.surface, in: Capsule())
            .foregroundStyle(YISUTheme.Color.brandEmphasis)
    }
}
