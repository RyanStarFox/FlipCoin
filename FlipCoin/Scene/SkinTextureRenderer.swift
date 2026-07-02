import SceneKit

#if os(macOS)
import AppKit
typealias PlatformImage = NSImage
typealias PlatformColor = NSColor
#else
import UIKit
typealias PlatformImage = UIImage
typealias PlatformColor = UIColor
#endif

struct SkinTextureRenderer {

    static func renderFace(_ text: String, size: CGSize) -> PlatformImage {
        #if os(macOS)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        guard let ctx = NSGraphicsContext.current?.cgContext else {
            return image
        }
        drawFace(ctx: ctx, text: text, size: size)
        return image
        #else
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            drawFace(ctx: ctx.cgContext, text: text, size: size)
        }
        #endif
    }

    static func renderSide(size: CGSize) -> PlatformImage {
        #if os(macOS)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        guard let ctx = NSGraphicsContext.current?.cgContext else {
            return image
        }
        drawSide(ctx: ctx, size: size)
        return image
        #else
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            drawSide(ctx: ctx.cgContext, size: size)
        }
        #endif
    }

    // MARK: - Core drawing (shared CGContext code)

    private static func drawFace(ctx: CGContext, text: String, size: CGSize) {
        let bounds = CGRect(origin: .zero, size: size)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(size.width, size.height) / 2

        // Silver coin face background with subtle radial gradient
        let colors = [
            CGColor(gray: 0.92, alpha: 1.0),
            CGColor(gray: 0.78, alpha: 1.0)
        ] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceGray(),
            colors: colors,
            locations: locations
        ) {
            ctx.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: radius * 0.1,
                endCenter: center, endRadius: radius,
                options: [.drawsAfterEndLocation]
            )
        }

        // Outer rim highlight
        ctx.setStrokeColor(CGColor(gray: 0.95, alpha: 0.6))
        ctx.setLineWidth(radius * 0.04)
        ctx.addArc(center: center, radius: radius * 0.94,
                    startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.strokePath()

        // Inner decorative ring
        ctx.setStrokeColor(CGColor(gray: 0.7, alpha: 0.4))
        ctx.setLineWidth(radius * 0.015)
        ctx.addArc(center: center, radius: radius * 0.75,
                    startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.strokePath()

        // Text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let fontSize: CGFloat
        if text.count <= 2 {
            fontSize = radius * 0.55
        } else if text.count <= 3 {
            fontSize = radius * 0.4
        } else {
            fontSize = radius * 0.3
        }

        // Use platform-appropriate font
        #if os(macOS)
        let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        #else
        let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        #endif

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: PlatformColor(white: 0.35, alpha: 0.9),
            .paragraphStyle: paragraphStyle
        ]

        let textSize = (text as NSString).size(withAttributes: attrs)
        let textRect = CGRect(
            x: bounds.midX - textSize.width / 2,
            y: bounds.midY - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        (text as NSString).draw(in: textRect, withAttributes: attrs)
    }

    private static func drawSide(ctx: CGContext, size: CGSize) {
        let bounds = CGRect(origin: .zero, size: size)

        // Base silver
        ctx.setFillColor(CGColor(gray: 0.88, alpha: 1.0))
        ctx.fill(bounds)

        // Reeded edge pattern — thin vertical lines simulating coin edge ridges
        let lineCount = 80
        let lineWidth = size.width / CGFloat(lineCount)
        for i in 0..<lineCount {
            let x = CGFloat(i) * lineWidth
            let shade: CGFloat = i % 3 == 0 ? 0.70 : (i % 5 == 0 ? 0.92 : 0.82)
            ctx.setFillColor(CGColor(gray: shade, alpha: 0.6))
            ctx.fill(CGRect(x: x, y: 0, width: lineWidth * 0.55, height: size.height))
        }
    }
}
