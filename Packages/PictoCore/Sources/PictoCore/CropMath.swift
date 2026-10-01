import Foundation
import CoreGraphics

/// Geometry of the square crop screen.
///
/// The image is shown filling a square of side `side`, scaled by `zoom` (>= 1)
/// and moved by `offset` from the centre.
public enum CropMath {
    public static let zoomRange: ClosedRange<CGFloat> = 1...6

    public static func baseScale(imageSize: CGSize, side: CGFloat) -> CGFloat {
        guard imageSize.width > 0, imageSize.height > 0 else { return 1 }
        return max(side / imageSize.width, side / imageSize.height)
    }

    /// Keeps the image covering the whole square.
    public static func clampedOffset(_ offset: CGSize, imageSize: CGSize, side: CGFloat, zoom: CGFloat) -> CGSize {
        let scale = baseScale(imageSize: imageSize, side: side) * zoom
        let maxX = max(0, (imageSize.width * scale - side) / 2)
        let maxY = max(0, (imageSize.height * scale - side) / 2)
        return CGSize(
            width: min(max(offset.width, -maxX), maxX),
            height: min(max(offset.height, -maxY), maxY)
        )
    }

    /// The visible square, in image coordinates (points of the image's natural size).
    public static func cropRect(imageSize: CGSize, side: CGFloat, zoom: CGFloat, offset: CGSize) -> CGRect {
        let scale = baseScale(imageSize: imageSize, side: side) * zoom
        let displayedWidth = imageSize.width * scale
        let displayedHeight = imageSize.height * scale
        let originX = (side - displayedWidth) / 2 + offset.width
        let originY = (side - displayedHeight) / 2 + offset.height
        return CGRect(x: -originX / scale, y: -originY / scale, width: side / scale, height: side / scale)
    }
}
