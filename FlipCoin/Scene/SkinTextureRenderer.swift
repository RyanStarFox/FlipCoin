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

        // Uniform silver disc — no gradient, no inner ring.
        // A clean, flat face so the coin reads clearly at any angle.
        ctx.setFillColor(CGColor(gray: 0.88, alpha: 1.0))
        ctx.fillEllipse(in: bounds)

        // Subtle outer rim — thin bright ring for coin edge definition
        ctx.setStrokeColor(CGColor(gray: 0.94, alpha: 0.8))
        ctx.setLineWidth(radius * 0.025)
        ctx.addArc(center: center, radius: radius * 0.97,
                    startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.strokePath()

        // Text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let fontSize: CGFloat
        if text.count <= 2 {
            fontSize = radius * 0.50
        } else if text.count <= 3 {
            fontSize = radius * 0.36
        } else {
            fontSize = radius * 0.28
        }

        #if os(macOS)
        let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        #else
        let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        #endif

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: PlatformColor(white: 0.25, alpha: 0.85),
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
