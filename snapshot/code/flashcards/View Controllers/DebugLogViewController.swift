import UIKit

class DebugLogViewController: UIViewController {

    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Debug Logs"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped)),
            UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearTapped))
        ]

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = .secondarySystemBackground
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        loadLogs()
    }

    private func loadLogs() {
        let logs = DebugLogService.shared.readLogs()
        textView.text = logs
        // Scroll to bottom
        if !logs.isEmpty {
            let range = NSRange(location: logs.count - 1, length: 1)
            textView.scrollRangeToVisible(range)
        }
    }

    @objc private func shareTapped() {
        let logs = DebugLogService.shared.readLogs()
        let vc = UIActivityViewController(activityItems: [logs], applicationActivities: nil)
        present(vc, animated: true)
    }

    @objc private func clearTapped() {
        let alert = UIAlertController(title: "Clear Logs?", message: "This cannot be undone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            DebugLogService.shared.clearLogs()
            self?.textView.text = "(Logs cleared)"
        })
        present(alert, animated: true)
    }
}
