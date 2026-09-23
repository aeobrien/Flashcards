import UIKit

@IBDesignable
class CircularProgressView: UIView {

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let valueLabel = UILabel()

    var progress: CGFloat = 0 {
        didSet {
            progressLayer.strokeEnd = progress
            updateLabel()
        }
    }

    var progressColor: UIColor = .systemGreen {
        didSet {
            progressLayer.strokeColor = progressColor.cgColor
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear

        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor.systemGray5.cgColor
        trackLayer.lineWidth = 8
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = 8
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)

        valueLabel.textAlignment = .center
        valueLabel.font = .systemFont(ofSize: 20, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(valueLabel)

        NSLayoutConstraint.activate([
            valueLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 8
        let startAngle: CGFloat = -.pi / 2
        let endAngle: CGFloat = startAngle + .pi * 2

        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
    }

    private func updateLabel() {
        let percentage = Int(progress * 100)
        valueLabel.text = "\(percentage)%"
    }

    static func colorForGrade(_ grade: Double) -> UIColor {
        switch grade {
        case 4.0...5.0: return .systemGreen
        case 3.0..<4.0: return .systemYellow
        case 2.0..<3.0: return .systemOrange
        default: return .systemRed
        }
    }
}
