import UIKit
import SwiftUI

extension UIImage {
    func edgeColor() -> Color {
        guard let cgImage = self.cgImage else { return .black }
        
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        guard let context = CGContext(data: nil,
                                     width: width,
                                     height: height,
                                     bitsPerComponent: bitsPerComponent,
                                     bytesPerRow: bytesPerRow,
                                     space: colorSpace,
                                     bitmapInfo: bitmapInfo) else { return .black }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else { return .black }
        let buffer = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        
        struct PixelColor {
            let r: CGFloat
            let g: CGFloat
            let b: CGFloat
            var luminance: CGFloat {
                return (0.2126 * r + 0.7152 * g + 0.0722 * b)
            }
        }
        
        var edgePixels: [PixelColor] = []
        
        // Collect all edge pixels
        for x in 0..<width {
            // Top edge
            let topOffset = (0 * width + x) * bytesPerPixel
            edgePixels.append(PixelColor(
                r: CGFloat(buffer[topOffset]),
                g: CGFloat(buffer[topOffset + 1]),
                b: CGFloat(buffer[topOffset + 2])
            ))
            
            // Bottom edge
            let bottomOffset = ((height - 1) * width + x) * bytesPerPixel
            edgePixels.append(PixelColor(
                r: CGFloat(buffer[bottomOffset]),
                g: CGFloat(buffer[bottomOffset + 1]),
                b: CGFloat(buffer[bottomOffset + 2])
            ))
        }
        
        for y in 1..<(height - 1) {
            // Left edge
            let leftOffset = (y * width + 0) * bytesPerPixel
            edgePixels.append(PixelColor(
                r: CGFloat(buffer[leftOffset]),
                g: CGFloat(buffer[leftOffset + 1]),
                b: CGFloat(buffer[leftOffset + 2])
            ))
            
            // Right edge
            let rightOffset = (y * width + (width - 1)) * bytesPerPixel
            edgePixels.append(PixelColor(
                r: CGFloat(buffer[rightOffset]),
                g: CGFloat(buffer[rightOffset + 1]),
                b: CGFloat(buffer[rightOffset + 2])
            ))
        }
        
        guard !edgePixels.isEmpty else { return .black }
        
        // Sort by luminance (darkest to brightest)
        let sortedPixels = edgePixels.sorted { $0.luminance < $1.luminance }
        
        // Take the top 50% (brightest half)
        let startIndex = sortedPixels.count / 2
        let lightestPixels = sortedPixels[startIndex...]
        
        var totalR: CGFloat = 0
        var totalG: CGFloat = 0
        var totalB: CGFloat = 0
        
        for pixel in lightestPixels {
            totalR += pixel.r
            totalG += pixel.g
            totalB += pixel.b
        }
        
        let count = CGFloat(lightestPixels.count)
        return Color(red: Double(totalR / count) / 255.0,
                    green: Double(totalG / count) / 255.0,
                    blue: Double(totalB / count) / 255.0)
    }
}
