#!/usr/bin/env swift
// Renders the app icon variants from AppIcon.svg into the asset catalog:
//     swift Design/render_icons.swift
// Each variant swaps the CSS variables at the top of the SVG, then AppKit (CoreSVG, macOS 11+)
// draws it at 1024 x 1024 with real transparency; QuickLook and sips would flatten it on white.
// Commit the PNGs it writes.

import AppKit

let iconSize = 1_024
let designDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let source = designDirectory.appendingPathComponent("AppIcon.svg")
let iconSet = designDirectory.deletingLastPathComponent()
    .appendingPathComponent("Solitaire/Resources/Assets.xcassets/AppIcon.appiconset")

/// The dark and tinted icons leave the background to the system, which draws its own gradient
/// under them; the tinted one is grey so the system's colour reads evenly. Everything else keeps
/// the light palette. `none` is the SVG keyword CoreSVG honours; `transparent` paints black.
let noFill = "none"
let variants: [(name: String, palette: [String: String])] = [
    ("AppIcon", [:]),
    ("AppIcon-Dark", ["felt": noFill]),
    ("AppIcon-Tinted", [
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

func render(_ svg: String) -> Data {
    guard let image = NSImage(data: Data(svg.utf8)) else { fail("CoreSVG cannot read the SVG") }
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: iconSize, pixelsHigh: iconSize, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    ) else { fail("cannot allocate the bitmap") }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let frame = NSRect(x: 0, y: 0, width: iconSize, height: iconSize)
    image.draw(in: frame, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    guard let png = bitmap.representation(using: .png, properties: [:]) else { fail("cannot encode the PNG") }
    return png
}

guard let svg = try? String(contentsOf: source, encoding: .utf8) else { fail("cannot read \(source.path)") }
for variant in variants {
    let destination = iconSet.appendingPathComponent("\(variant.name).png")
    do {
        try render(withPalette(svg, variant.palette)).write(to: destination)
    } catch {
        fail("cannot write \(destination.path): \(error)")
    }
    print("wrote \(destination.path)")
}
