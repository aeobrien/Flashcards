import UIKit

class LoadingOverlayView: UIView {

    private let containerView = UIView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let messageLabel = UILabel()
    private let detailLabel = UILabel()
    private let progressBar = UIProgressView(progressViewStyle: .default)

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        alpha = 0

        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.cornerCurve = .continuous
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        spinner.color = .label
        spinner.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(spinner)

        messageLabel.text = "Loading..."
        messageLabel.textAlignment = .center
        messageLabel.font = .preferredFont(forTextStyle: .headline)
        messageLabel.textColor = .label
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)

        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.progress = 0
        progressBar.trackTintColor = .systemGray5
        progressBar.progressTintColor = .systemBlue
        progressBar.isHidden = true
        containerView.addSubview(progressBar)

        detailLabel.text = ""
        detailLabel.textAlignment = .center
        detailLabel.font = .preferredFont(forTextStyle: .caption1)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 0
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(detailLabel)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 260),

            spinner.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            spinner.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            messageLabel.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            progressBar.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 12),
            progressBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            detailLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 8),
            detailLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            detailLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            detailLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24)
        ])
    }

    func show(in parentView: UIView, message: String = "Loading...") {
        messageLabel.text = message
        detailLabel.text = ""
        progressBar.progress = 0
        progressBar.isHidden = true
        frame = parentView.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        parentView.addSubview(self)
        spinner.startAnimating()

        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }

    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.spinner.stopAnimating()
            self.removeFromSuperview()
            completion?()
        })
    }

    func updateMessage(_ message: String) {
        messageLabel.text = message
    }

    func updateDetail(_ text: String) {
        detailLabel.text = text
    }

    func updateProgress(_ fraction: Float) {
        progressBar.isHidden = false
        progressBar.setProgress(fraction, animated: true)
    }
}
