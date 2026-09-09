import UIKit

enum MicrophoneButtonState {
    case idle
    case recording
    case processing
}

@IBDesignable
class MicrophoneButton: UIView {

    private let iconImageView = UIImageView()
    private let pulsingLayer = CAShapeLayer()
    private let spinnerLayer = CAShapeLayer()

    private(set) var currentState: MicrophoneButtonState = .idle

    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .systemGray5
        clipsToBounds = false

        // Pulsing ring layer
        pulsingLayer.fillColor = UIColor.clear.cgColor
        pulsingLayer.strokeColor = UIColor.systemRed.cgColor
        pulsingLayer.lineWidth = 3
        pulsingLayer.opacity = 0
        layer.addSublayer(pulsingLayer)

        // Spinner layer
        spinnerLayer.fillColor = UIColor.clear.cgColor
        spinnerLayer.strokeColor = UIColor.systemOrange.cgColor
        spinnerLayer.lineWidth = 3
        spinnerLayer.strokeEnd = 0.3
        spinnerLayer.opacity = 0
        layer.addSublayer(spinnerLayer)

        // Mic icon
        iconImageView.image = UIImage(systemName: "mic.fill")
        iconImageView.tintColor = .label
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.4),
            iconImageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.4)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = bounds.width / 2 + 6
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        pulsingLayer.path = path.cgPath
        spinnerLayer.path = path.cgPath
    }

    @objc private func handleTap() {
        onTap?()
    }

    func setState(_ state: MicrophoneButtonState) {
        currentState = state
        stopAnimations()

        switch state {
        case .idle:
            backgroundColor = .systemGray5
            iconImageView.tintColor = .label
            iconImageView.image = UIImage(systemName: "mic.fill")
            pulsingLayer.opacity = 0
            spinnerLayer.opacity = 0

        case .recording:
            backgroundColor = .systemRed.withAlphaComponent(0.15)
            iconImageView.tintColor = .systemRed
            iconImageView.image = UIImage(systemName: "stop.fill")
            pulsingLayer.opacity = 1
            spinnerLayer.opacity = 0
            startPulsingAnimation()

        case .processing:
            backgroundColor = .systemOrange.withAlphaComponent(0.15)
            iconImageView.tintColor = .systemOrange
            iconImageView.image = UIImage(systemName: "waveform")
            pulsingLayer.opacity = 0
            spinnerLayer.opacity = 1
            startSpinnerAnimation()
        }
    }

    private func startPulsingAnimation() {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.15
        scaleAnimation.duration = 0.8
        scaleAnimation.autoreverses = true
        scaleAnimation.repeatCount = .infinity

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.4
        opacityAnimation.duration = 0.8
        opacityAnimation.autoreverses = true
        opacityAnimation.repeatCount = .infinity

        pulsingLayer.add(scaleAnimation, forKey: "pulsing_scale")
        pulsingLayer.add(opacityAnimation, forKey: "pulsing_opacity")
    }

    private func startSpinnerAnimation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 1.0
        rotation.repeatCount = .infinity
        spinnerLayer.add(rotation, forKey: "spinner_rotation")
    }

    private func stopAnimations() {
        pulsingLayer.removeAllAnimations()
        spinnerLayer.removeAllAnimations()
    }
}
