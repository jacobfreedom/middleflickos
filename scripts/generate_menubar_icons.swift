#!/usr/bin/swift
import AppKit
import Foundation

func makeIconImage(size: CGFloat = 1024, background: NSColor = .clear, foreground: NSColor = .black) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    defer { img.unlockFocus() }

    let w = size
    let h = size

    // Background
    background.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: w, height: h)).fill()

    // Foreground
    foreground.setFill()

    // Rounded corner radius
    let corner: CGFloat = max(8, size * 0.03)
    func roundedRect(_ rect: NSRect) {
        let path = NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner)
        path.fill()
    }

    // Palm
    let palmWidth: CGFloat = 0.44 * w
    let palmHeight: CGFloat = 0.22 * h
    let palmX = (w - palmWidth) / 2
    let palmY: CGFloat = 0.18 * h
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
    fputs("Usage: generate_menubar_icons.swift /path/to/output_1024.png\n", stderr)
    exit(2)
}
let outputPath = args[1]
let url = URL(fileURLWithPath: outputPath)

let image = makeIconImage(size: 1024, background: .clear, foreground: .white)

do {
    try writePNG(image, to: url)
    print("Wrote 1024px menubar base icon to: \(url.path)")
} catch {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}
