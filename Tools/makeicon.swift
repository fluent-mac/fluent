import AppKit

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let size = 1024

func render(_ name: String, _ draw: () -> Void) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/\(name)"))
}

let top = NSColor(srgbRed: 0.42, green: 0.82, blue: 1.0, alpha: 1)
let bottom = NSColor(srgbRed: 0.20, green: 0.36, blue: 0.98, alpha: 1)

// keycap
func keycap(cutout: Bool) {
    let shadow = NSShadow()
    shadow.shadowOffset = NSSize(width: 0, height: -16)
    shadow.shadowBlurRadius = 40
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    let body = NSBezierPath(roundedRect: NSRect(x: 232, y: 262, width: 560, height: 540), xRadius: 140, yRadius: 140)
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    NSColor.white.setFill()
    body.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(starting: NSColor.white, ending: NSColor(srgbRed: 0.86, green: 0.89, blue: 0.96, alpha: 1))!
        .draw(in: body, angle: -90)
    // dished top
    let face = NSBezierPath(roundedRect: NSRect(x: 292, y: 322, width: 440, height: 420), xRadius: 100, yRadius: 100)
    NSColor.black.withAlphaComponent(0.07).setStroke()
    face.lineWidth = 4
    face.stroke()
    // caret
    let caret = NSBezierPath(roundedRect: NSRect(x: 482, y: 392, width: 60, height: 280), xRadius: 30, yRadius: 30)
    if cutout {
        NSGraphicsContext.current!.compositingOperation = .clear
        caret.fill()
        NSGraphicsContext.current!.compositingOperation = .sourceOver
    } else {
        NSGradient(starting: top, ending: bottom)!.draw(in: caret, angle: -90)
    }
}

render("glyph.png") { keycap(cutout: true) }

render("fallback.png") {
    let rect = NSRect(x: 100, y: 100, width: 824, height: 824)
    let path = NSBezierPath(roundedRect: rect, xRadius: 185, yRadius: 185)
    NSGradient(starting: bottom, ending: top)!.draw(in: path, angle: 90)
    keycap(cutout: false)
}
