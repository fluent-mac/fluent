import AppKit
let w = 660, h = 400
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
NSColor(calibratedWhite: 0.97, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: w, height: h).fill()
let p = NSBezierPath()
p.move(to: NSPoint(x: 270, y: 200)); p.line(to: NSPoint(x: 390, y: 200))
p.move(to: NSPoint(x: 370, y: 220)); p.line(to: NSPoint(x: 392, y: 200)); p.line(to: NSPoint(x: 370, y: 180))
p.lineWidth = 6; p.lineCapStyle = .round; p.lineJoinStyle = .round
NSColor(calibratedWhite: 0.7, alpha: 1).setStroke(); p.stroke()
let t = "Drag Fluent to Applications" as NSString
let a: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 18, weight: .medium), .foregroundColor: NSColor(calibratedWhite: 0.35, alpha: 1)]
let s = t.size(withAttributes: a)
t.draw(at: NSPoint(x: (CGFloat(w) - s.width) / 2, y: 330), withAttributes: a)
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
