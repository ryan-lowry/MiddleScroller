//
//  AnchorOverlayView.swift
//  MiddleScroller
//

import Cocoa

final class AnchorOverlayView: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let bounds = self.bounds
        let centerX = bounds.midX
        let centerY = bounds.midY
        let outerRadius: CGFloat = bounds.width / 2 - 2
        let innerRadius: CGFloat = 6

        // Colors
        let fillColor = NSColor(white: 0.95, alpha: 0.9)
        let strokeColor = NSColor(white: 0.3, alpha: 0.9)
        let arrowColor = NSColor(white: 0.2, alpha: 0.9)

        // Draw outer circle with fill and stroke
        context.setFillColor(fillColor.cgColor)
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(1.5)

        let outerCircleRect = NSRect(x: centerX - outerRadius,
                                      y: centerY - outerRadius,
                                      width: outerRadius * 2,
                                      height: outerRadius * 2)
        context.fillEllipse(in: outerCircleRect)
        context.strokeEllipse(in: outerCircleRect)

        // Draw center dot
        context.setFillColor(arrowColor.cgColor)
        let centerDotRect = NSRect(x: centerX - innerRadius,
                                    y: centerY - innerRadius,
                                    width: innerRadius * 2,
                                    height: innerRadius * 2)
        context.fillEllipse(in: centerDotRect)

        // Draw directional arrows
        let arrowLength: CGFloat = 8
        let arrowWidth: CGFloat = 5
        let arrowOffset: CGFloat = outerRadius - 10

        context.setFillColor(arrowColor.cgColor)

        // Up arrow
        drawArrow(context: context,
                  at: CGPoint(x: centerX, y: centerY + arrowOffset),
                  direction: .up,
                  length: arrowLength,
                  width: arrowWidth)

        // Down arrow
        drawArrow(context: context,
                  at: CGPoint(x: centerX, y: centerY - arrowOffset),
                  direction: .down,
                  length: arrowLength,
                  width: arrowWidth)

        // Left arrow
        drawArrow(context: context,
                  at: CGPoint(x: centerX - arrowOffset, y: centerY),
                  direction: .left,
                  length: arrowLength,
                  width: arrowWidth)

        // Right arrow
        drawArrow(context: context,
                  at: CGPoint(x: centerX + arrowOffset, y: centerY),
                  direction: .right,
                  length: arrowLength,
                  width: arrowWidth)
    }

    private enum ArrowDirection {
        case up, down, left, right
    }

    private func drawArrow(context: CGContext, at point: CGPoint, direction: ArrowDirection, length: CGFloat, width: CGFloat) {
        context.saveGState()

        let path = CGMutablePath()

        switch direction {
        case .up:
            path.move(to: CGPoint(x: point.x, y: point.y + length / 2))
            path.addLine(to: CGPoint(x: point.x - width / 2, y: point.y - length / 2))
            path.addLine(to: CGPoint(x: point.x + width / 2, y: point.y - length / 2))

        case .down:
            path.move(to: CGPoint(x: point.x, y: point.y - length / 2))
            path.addLine(to: CGPoint(x: point.x - width / 2, y: point.y + length / 2))
            path.addLine(to: CGPoint(x: point.x + width / 2, y: point.y + length / 2))

        case .left:
            path.move(to: CGPoint(x: point.x - length / 2, y: point.y))
            path.addLine(to: CGPoint(x: point.x + length / 2, y: point.y - width / 2))
            path.addLine(to: CGPoint(x: point.x + length / 2, y: point.y + width / 2))

        case .right:
            path.move(to: CGPoint(x: point.x + length / 2, y: point.y))
            path.addLine(to: CGPoint(x: point.x - length / 2, y: point.y - width / 2))
            path.addLine(to: CGPoint(x: point.x - length / 2, y: point.y + width / 2))
        }

        path.closeSubpath()
        context.addPath(path)
        context.fillPath()

        context.restoreGState()
    }
}
