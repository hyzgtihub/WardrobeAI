import SwiftUI
import UIKit

@MainActor
private final class PrivateGarmentImageCache {
    static let shared = PrivateGarmentImageCache()
    private let images = NSCache<NSString, UIImage>()

    func image(for path: String) -> UIImage? { images.object(forKey: path as NSString) }
    func insert(_ image: UIImage, for path: String) { images.setObject(image, forKey: path as NSString) }
}

struct PrivateGarmentImageView: View {
    let path: String
    let repository: any GarmentImageRepository

    @State private var state: LoadState = .loading

    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView().tint(YISUTheme.Color.brandEmphasis)
            case let .loaded(image):
                Image(uiImage: image).resizable().scaledToFit()
            case .failed:
                VStack(spacing: YISUTheme.Spacing.sm) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.system(size: 30, weight: .light))
                    Text("图片加载失败").font(YISUTheme.Typography.footnote)
                }
                .foregroundStyle(YISUTheme.Color.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("衣物照片")
        .task(id: path) { await load() }
    }

    private func load() async {
        if let cached = PrivateGarmentImageCache.shared.image(for: path) {
            state = .loaded(cached)
            return
        }
        state = .loading
        do {
            let data = try await repository.downloadImage(path: path)
            guard let image = UIImage(data: data) else {
                state = .failed
                return
            }
            PrivateGarmentImageCache.shared.insert(image, for: path)
            state = .loaded(image)
        } catch {
            state = .failed
        }
    }

    private enum LoadState {
        case loading
        case loaded(UIImage)
        case failed
    }
}
