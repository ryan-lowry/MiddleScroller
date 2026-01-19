#!/usr/bin/env swift
import Cocoa

// DMG background dimensions
let width: CGFloat = 660
let height: CGFloat = 480

// Icon positions (matching create-dmg settings)
let appIconX: CGFloat = 180
let applicationsX: CGFloat = 480
let iconY: CGFloat = 240

// Create the image
let image = NSImage(size: NSSize(width: width, height: height))

image.lockFocus()

// Draw gradient background (light gray to white)
let gradient = NSGradient(colors: [
    NSColor(white: 0.95, alpha: 1.0),
    NSColor(white: 0.98, alpha: 1.0)
])!
gradient.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: 90)

// Draw subtle arrow from app icon area to Applications area
let arrowPath = NSBezierPath()
let arrowY = height - iconY  // Flip Y coordinate for Cocoa
let arrowStartX = appIconX + 70  // After app icon
let arrowEndX = applicationsX - 70  // Before Applications icon

// Arrow body
arrowPath.move(to: NSPoint(x: arrowStartX, y: arrowY))
arrowPath.line(to: NSPoint(x: arrowEndX - 20, y: arrowY))

// Arrow head
arrowPath.move(to: NSPoint(x: arrowEndX - 35, y: arrowY + 15))
arrowPath.line(to: NSPoint(x: arrowEndX - 20, y: arrowY))
arrowPath.line(to: NSPoint(x: arrowEndX - 35, y: arrowY - 15))

// Style and draw the arrow
NSColor(white: 0.6, alpha: 0.5).setStroke()
arrowPath.lineWidth = 3
arrowPath.lineCapStyle = .round
arrowPath.lineJoinStyle = .round
arrowPath.stroke()

image.unlockFocus()

// Save as PNG
guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("Failed to create PNG data")
    exit(1)
}

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "dmg-background.png"

do {
    try pngData.write(to: URL(fileURLWithPath: outputPath))
    print("Created DMG background: \(outputPath)")
} catch {
    print("Failed to write PNG: \(error)")
    exit(1)
}
