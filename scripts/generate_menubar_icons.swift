#!/usr/bin/swift
import AppKit
import Foundation

func makeMenuBarIcon(size: CGFloat, yOffset: CGFloat, insetRatio: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    defer { img.unlockFocus() }

    NSColor.clear.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

    let inset = size * insetRatio
    let w = size - inset * 2
    let h = size - inset * 2
    let originX = inset
    let originY = inset

    NSColor.black.setFill()

    let corner: CGFloat = max(1.5, w * 0.10)
    func roundedRect(_ rect: NSRect) {
        let path = NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner)
        path.fill()
    }

    // Palm
    let palmWidth: CGFloat = 0.44 * w
    let palmHeight: CGFloat = 0.22 * h
    let palmX = originX + (w - palmWidth) / 2
    let palmY: CGFloat = originY + 0.18 * h + yOffset
    roundedRect(NSRect(x: palmX, y: palmY, width: palmWidth, height: palmHeight))

    // Fingers
    let fingerGap: CGFloat = 0.04 * w
    let fingerWidth: CGFloat = (palmWidth - 2 * fingerGap) / 3
    let leftFingerHeight: CGFloat = 0.34 * h
    let middleFingerHeight: CGFloat = 0.56 * h
    let rightFingerHeight: CGFloat = 0.38 * h
    let fingerBottom = palmY + palmHeight + (0.03 * h)

    let leftX = palmX
    let midX = palmX + fingerWidth + fingerGap
    let rightX = palmX + 2 * (fingerWidth + fingerGap)

    roundedRect(NSRect(x: leftX, y: fingerBottom, width: fingerWidth, height: leftFingerHeight))
    roundedRect(NSRect(x: midX, y: fingerBottom, width: fingerWidth, height: middleFingerHeight))
    roundedRect(NSRect(x: rightX, y: fingerBottom, width: fingerWidth, height: rightFingerHeight))

    return img
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGen", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
    }
    try png.write(to: url)
}

let args = CommandLine.arguments
if args.count < 2 {
    fputs("Usage: generate_menubar_icons.swift /path/to/MenuBarIcon.imageset\n", stderr)
    exit(2)
}

let outDir = URL(fileURLWithPath: args[1], isDirectory: true)

let sizes: [(CGFloat, String)] = [
    (22, "MenuBarIcon_22.png"),
    (44, "MenuBarIcon_44.png"),
    (66, "MenuBarIcon_66.png")
]

for (size, name) in sizes {
    // 22px canvas with ~16px glyph area is a common, crisp baseline.
    let icon = makeMenuBarIcon(size: size, yOffset: -0.01 * size, insetRatio: 0.14)
    let url = outDir.appendingPathComponent(name)
    try writePNG(icon, to: url)
    print("Wrote \(url.path)")
}
