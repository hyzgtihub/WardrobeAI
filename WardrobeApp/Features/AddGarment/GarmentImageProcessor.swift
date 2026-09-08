import CoreGraphics
import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

enum GarmentImageProcessingError: Error, Equatable, Sendable {
    case invalidImage
    case unableToMeetSizeLimit
}

struct GarmentImageProcessor: Sendable {
    static let maximumDimension: CGFloat = 2_048
    static let maximumBytes = 5 * 1_024 * 1_024
    static let initialQuality: CGFloat = 0.8
    static let minimumQuality: CGFloat = 0.45

    private static let compressionQualities: [CGFloat] = [initialQuality, 0.7, 0.6, 0.5, minimumQuality]

    let maximumBytes: Int

    init(maximumBytes: Int = Self.maximumBytes) {
        self.maximumBytes = maximumBytes
    }

    func process(_ data: Data) throws -> GarmentImage {
        guard let sourceImage = UIImage(data: data), sourceImage.size.width > 0, sourceImage.size.height > 0 else {
            throw GarmentImageProcessingError.invalidImage
        }

        let pixelSize = Self.targetSize(for: sourceImage.size)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let renderedImage = UIGraphicsImageRenderer(size: pixelSize, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: pixelSize))
            sourceImage.draw(in: CGRect(origin: .zero, size: pixelSize))
        }

        guard let cgImage = renderedImage.cgImage else {
            throw GarmentImageProcessingError.invalidImage
        }

        for quality in Self.compressionQualities {
            guard let encoded = Self.encodeJPEG(cgImage, quality: quality) else {
                throw GarmentImageProcessingError.invalidImage
            }
            if encoded.count <= maximumBytes {
                return GarmentImage(data: encoded, pixelSize: pixelSize)
            }
        }

        throw GarmentImageProcessingError.unableToMeetSizeLimit
    }

    private static func targetSize(for sourceSize: CGSize) -> CGSize {
        let longestSide = max(sourceSize.width, sourceSize.height)
        guard longestSide > maximumDimension else {
            return CGSize(width: sourceSize.width.rounded(), height: sourceSize.height.rounded())
        }

        let scale = maximumDimension / longestSide
        return CGSize(
            width: (sourceSize.width * scale).rounded(),
            height: (sourceSize.height * scale).rounded()
        )
    }

    private static func encodeJPEG(_ image: CGImage, quality: CGFloat) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }

        let properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return strippingAPP1Segments(from: data as Data)
    }

    /// ImageIO may synthesize an EXIF block containing pixel dimensions even
    /// when no source metadata is supplied. Removing APP1 keeps the encoded
    /// pixels while ensuring EXIF, GPS, and XMP cannot leave the device.
    private static func strippingAPP1Segments(from data: Data) -> Data? {
        let bytes = [UInt8](data)
        guard bytes.count >= 4, bytes[0] == 0xFF, bytes[1] == 0xD8 else { return nil }

        var output = Data(bytes.prefix(2))
        var offset = 2

        while offset < bytes.count {
            guard bytes[offset] == 0xFF, offset + 1 < bytes.count else { return nil }
            let marker = bytes[offset + 1]

            if marker == 0xDA || marker == 0xD9 {
                output.append(contentsOf: bytes[offset...])
                return output
            }

            if marker == 0x01 || (0xD0...0xD7).contains(marker) {
                output.append(contentsOf: bytes[offset..<(offset + 2)])
                offset += 2
                continue
            }

            guard offset + 3 < bytes.count else { return nil }
            let length = Int(bytes[offset + 2]) << 8 | Int(bytes[offset + 3])
            let segmentEnd = offset + 2 + length
            guard length >= 2, segmentEnd <= bytes.count else { return nil }

            if marker != 0xE1 {
                output.append(contentsOf: bytes[offset..<segmentEnd])
            }
            offset = segmentEnd
        }

        return nil
    }
}
