#!/usr/bin/env swift
// Renders the app icon variants from AppIcon.svg into the asset catalog:
//     swift Design/render_icons.swift
// Each variant swaps the CSS variables at the top of the SVG, then AppKit (CoreSVG, macOS 11+)
// draws it at 1024 x 1024 with real transparency; QuickLook and sips would flatten it on white.
// The light icon is written without an alpha channel: App Store Connect rejects an App Store icon
// that has one, even when every pixel is opaque (ITMS-90717). Commit the PNGs it writes.

import AppKit
import ImageIO
import UniformTypeIdentifiers

let iconSize = 1_024
let designDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let source = designDirectory.appendingPathComponent("AppIcon.svg")
let iconSet = designDirectory.deletingLastPathComponent()
    .appendingPathComponent("Solitaire/Resources/Assets.xcassets/AppIcon.appiconset")

/// The dark and tinted icons leave the background to the system, which draws its own gradient
/// under them; the tinted one is grey so the system's colour reads evenly. Everything else keeps
/// the light palette. `none` is the SVG keyword CoreSVG honours; `transparent` paints black.
let noFill = "none"
let variants: [(name: String, isOpaque: Bool, palette: [String: String])] = [
    ("AppIcon", true, [:]),
    ("AppIcon-Dark", false, ["felt": noFill]),
    ("AppIcon-Tinted", false, [
        "felt": noFill,
        "face": "#E8E8E8",
        "back": "#7A7A7A",
        "back-inner": "rgba(255, 255, 255, 0.7)",
        "border": "rgba(0, 0, 0, 0.3)",
        "pip": "#3C3C3C",
        "shadow": "rgba(0, 0, 0, 0.25)",
    ]),
]

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

func withPalette(_ svg: String, _ palette: [String: String]) -> String {
    var svg = svg
    for (name, value) in palette {
        let pattern = "--\(name): [^;]+;"
        guard let range = svg.range(of: pattern, options: .regularExpression) else {
            fail("\(source.lastPathComponent) has no CSS variable --\(name)")
        }
        svg.replaceSubrange(range, with: "--\(name): \(value);")
    }
    return svg
}

let bitsPerComponent = 8
let bytesPerPixel = 4

/// Draws the SVG into an 8-bit RGB bitmap, with alpha or with the fourth byte skipped, so the
/// PNG keeps or drops its alpha channel.
func render(_ svg: String, isOpaque: Bool) -> Data {
    guard let image = NSImage(data: Data(svg.utf8)) else { fail("CoreSVG cannot read the SVG") }
    let alpha: CGImageAlphaInfo = isOpaque ? .noneSkipLast : .premultipliedLast
    guard let space = CGColorSpace(name: CGColorSpace.sRGB), let context = CGContext(
        data: nil, width: iconSize, height: iconSize, bitsPerComponent: bitsPerComponent,
        bytesPerRow: iconSize * bytesPerPixel, space: space, bitmapInfo: alpha.rawValue
    ) else { fail("cannot allocate the bitmap") }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    let frame = NSRect(x: 0, y: 0, width: iconSize, height: iconSize)
    image.draw(in: frame, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    guard let bitmap = context.makeImage() else { fail("cannot read the bitmap") }
    return png(bitmap)
}

func png(_ image: CGImage) -> Data {
    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)
    else { fail("cannot create the PNG encoder") }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { fail("cannot encode the PNG") }
    return data as Data
}

guard let svg = try? String(contentsOf: source, encoding: .utf8) else { fail("cannot read \(source.path)") }
for variant in variants {
    let destination = iconSet.appendingPathComponent("\(variant.name).png")
    do {
        try render(withPalette(svg, variant.palette), isOpaque: variant.isOpaque).write(to: destination)
    } catch {
        fail("cannot write \(destination.path): \(error)")
    }
    print("wrote \(destination.path)")
}
