import ImageIO
import UIKit
import UniformTypeIdentifiers

/// 사진 보관함에서 고른 원본 이미지를 화면·업로드에 맞는 크기로 줄인다.
/// 원본을 통째로 디코딩하지 않고 ImageIO 썸네일로 줄여 메모리 사용을 낮춘다.
/// 메인 스레드를 막지 않도록 백그라운드에서 호출한다.
nonisolated enum ImageDownsampler {
    /// 긴 변을 `maxPixelSize`로 줄인 JPEG 데이터.
    static func downsampledJPEGData(from data: Data, maxPixelSize: CGFloat, quality: CGFloat = 0.8) -> Data? {
        guard let image = cgImage(from: data, maxPixelSize: maxPixelSize) else { return nil }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output, UTType.jpeg.identifier as CFString, 1, nil
        ) else { return nil }

        CGImageDestinationAddImage(destination, image, [
            kCGImageDestinationLossyCompressionQuality: quality
        ] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }

    /// 긴 변을 `maxPixelSize`로 줄여 디코딩한 이미지.
    static func image(from data: Data, maxPixelSize: CGFloat) -> UIImage? {
        cgImage(from: data, maxPixelSize: maxPixelSize).map(UIImage.init(cgImage:))
    }

    /// EXIF 촬영 시각. 없으면 nil.
    static func capturedDate(of data: Data) -> Date? {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
            let value = exif[kCGImagePropertyExifDateTimeOriginal] as? String
        else { return nil }

        return exifDateFormatter.date(from: value)
    }

    private static func cgImage(from data: Data, maxPixelSize: CGFloat) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, [
            kCGImageSourceShouldCache: false
        ] as CFDictionary) else { return nil }

        return CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary)
    }

    private static let exifDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter
    }()
}
