import UIKit

class OverlayView: UIView {

    var pathPoints: [CGPoint] = []
    var pathColor: UIColor = .red

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        ctx.setStrokeColor(pathColor.cgColor)
        ctx.setLineWidth(2.0)

        guard pathPoints.count > 1 else { return }

        ctx.move(to: pathPoints[0])
        for point in pathPoints.dropFirst() {
            ctx.addLine(to: point)
        }
        ctx.strokePath()
    }

    func updatePath(_ points: [CGPoint]) {
        pathPoints = points
        setNeedsDisplay()
    }

    func clearPath() {
        pathPoints.removeAll()
        setNeedsDisplay()
    }
}
