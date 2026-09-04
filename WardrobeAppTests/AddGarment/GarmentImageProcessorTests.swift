import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import YISU

@Suite("Garment image processor")
struct GarmentImageProcessorTests {
    @Test
    func scalesOrientedImageAndCapsOutput() throws {
        let output = try GarmentImageProcessor().process(Self.fixture("garment-photo-landscape"))

        #expect(max(output.pixelSize.width, output.pixelSize.height) == 2048)
        #expect(output.pixelSize.width < output.pixelSize.height)
        #expect(output.data.count <= 5 * 1024 * 1024)

        let source = try #require(CGImageSourceCreateWithData(output.data as CFData, nil))
        #expect(CGImageSourceGetType(source) as String? == UTType.jpeg.identifier)
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        #expect((properties[kCGImagePropertyOrientation] as? Int ?? 1) == 1)
    }

    @Test
    func removesExifAndGPSMetadata() throws {
        let input = Self.fixture("garment-photo-metadata")
        let inputSource = try #require(CGImageSourceCreateWithData(input as CFData, nil))
        let inputProperties = try #require(
            CGImageSourceCopyPropertiesAtIndex(inputSource, 0, nil) as? [CFString: Any]
        )
        #expect(inputProperties[kCGImagePropertyExifDictionary] != nil)
        #expect(inputProperties[kCGImagePropertyGPSDictionary] != nil)

        let output = try GarmentImageProcessor().process(input)
        let outputSource = try #require(CGImageSourceCreateWithData(output.data as CFData, nil))
        let outputProperties = try #require(
            CGImageSourceCopyPropertiesAtIndex(outputSource, 0, nil) as? [CFString: Any]
        )

        #expect(outputProperties[kCGImagePropertyExifDictionary] == nil)
        #expect(outputProperties[kCGImagePropertyGPSDictionary] == nil)
    }

    @Test
    func doesNotUpscaleSmallImages() throws {
        let output = try GarmentImageProcessor().process(Self.fixture("garment-photo-metadata"))

        #expect(output.pixelSize == CGSize(width: 640, height: 480))
    }

    @Test
    func rejectsInvalidImageBytes() {
        #expect(throws: GarmentImageProcessingError.invalidImage) {
            try GarmentImageProcessor().process(Data("not-an-image".utf8))
        }
    }

    @Test
    func reportsWhenNoEncodingCanMeetTheByteLimit() {
        #expect(throws: GarmentImageProcessingError.unableToMeetSizeLimit) {
            try GarmentImageProcessor(maximumBytes: 1)
                .process(Self.fixture("garment-photo-metadata"))
        }
    }

    private static func fixture(_ name: String) -> Data {
        let url = Bundle(for: FixtureBundleToken.self).url(forResource: name, withExtension: "jpg")!
        return try! Data(contentsOf: url)
    }
}

private final class FixtureBundleToken {}
