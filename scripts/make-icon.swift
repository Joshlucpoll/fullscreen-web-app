// Draws a placeholder 1024px app icon: a globe inside fullscreen corner brackets.
// Run: swift scripts/make-icon.swift WebApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png
// Or replace AppIcon.png with any opaque 1024x1024 PNG.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024.0
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                    space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)! // icons must be opaque

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

let gradient = CGGradient(colorsSpace: space, colors: [rgb(0x3B82F6), rgb(0x1D4ED8)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
ctx.setStrokeColor(rgb(0xFFFFFF)); ctx.setLineCap(.round); ctx.setLineJoin(.round)

// Fullscreen brackets: one rounded L per corner, inside the iOS corner mask.
let inset = 190.0, arm = 150.0
ctx.setLineWidth(52)
for (cx, cy, dx, dy) in [(inset, inset, 1.0, 1.0), (size - inset, inset, -1.0, 1.0),
                         (inset, size - inset, 1.0, -1.0), (size - inset, size - inset, -1.0, -1.0)] {
    ctx.move(to: CGPoint(x: cx, y: cy + dy * arm))
    ctx.addArc(tangent1End: CGPoint(x: cx, y: cy), tangent2End: CGPoint(x: cx + dx * arm, y: cy), radius: 120)
    ctx.addLine(to: CGPoint(x: cx + dx * arm, y: cy))
}
ctx.strokePath()

// Globe: outline, one meridian, equator and two latitude lines.
let c = size / 2, r = 175.0
ctx.setLineWidth(34)
ctx.strokeEllipse(in: CGRect(x: c - r, y: c - r, width: 2 * r, height: 2 * r))
ctx.strokeEllipse(in: CGRect(x: c - r * 0.42, y: c - r, width: 2 * r * 0.42, height: 2 * r))
ctx.setLineWidth(26)
for y in [0.0, 0.5, -0.5] {
    let half = r * (1 - y * y).squareRoot()
    ctx.move(to: CGPoint(x: c - half, y: c + y * r)); ctx.addLine(to: CGPoint(x: c + half, y: c + y * r))
}
ctx.strokePath()

let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("could not write \(out)") }
