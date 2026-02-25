import UIKit

class AIInputViewController: UIViewController {

    // MARK: - Properties

    private let aiService = AICardGenerationService()
    private let loadingOverlay = LoadingOverlayView()

    private let deckNameTextField = UITextField()
    private let notesTextView = UITextView()
    private let preSummaryTextView = UITextView()
    private var preSummaryContainer: UIStackView!
    private let extractButton = GradientButton(frame: .zero)
    private var scrollView: UIScrollView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Generate with AI"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        setupUI()
        hideKeyboardWhenTappedAround()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupUI() {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.keyboardDismissMode = .interactive
        view.addSubview(sv)
        scrollView = sv

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        sv.addSubview(contentStack)

        // Deck name
        let nameLabel = UILabel()
        nameLabel.text = "Deck Name"
        nameLabel.font = .preferredFont(forTextStyle: .headline)
        contentStack.addArrangedSubview(nameLabel)

        deckNameTextField.borderStyle = .roundedRect
        deckNameTextField.placeholder = "e.g., Biology Chapter 5"
        deckNameTextField.font = .preferredFont(forTextStyle: .body)
        deckNameTextField.returnKeyType = .next
        deckNameTextField.delegate = self
        deckNameTextField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        contentStack.addArrangedSubview(deckNameTextField)

        // Notes
        let notesLabel = UILabel()
        notesLabel.text = "Study Materials"
        notesLabel.font = .preferredFont(forTextStyle: .headline)
        contentStack.addArrangedSubview(notesLabel)

        let notesHint = UILabel()
        notesHint.text = "Paste your study notes, textbook excerpts, or lecture content below."
        notesHint.font = .preferredFont(forTextStyle: .caption1)
        notesHint.textColor = .secondaryLabel
        notesHint.numberOfLines = 0
        contentStack.addArrangedSubview(notesHint)

        notesTextView.font = .preferredFont(forTextStyle: .body)
        notesTextView.layer.cornerRadius = 8
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.borderColor = UIColor.separator.cgColor
        notesTextView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        notesTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true

        // Done toolbar for the text views
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboardView))
        toolbar.items = [flexSpace, doneItem]
        notesTextView.inputAccessoryView = toolbar
        deckNameTextField.inputAccessoryView = toolbar

        contentStack.addArrangedSubview(notesTextView)

        // Write-to-Learn section (collapsible)
        let preSummaryStack = UIStackView()
        preSummaryStack.axis = .vertical
        preSummaryStack.spacing = 8
        preSummaryContainer = preSummaryStack

        let toggleButton = UIButton(type: .system)
        toggleButton.setTitle("Write-to-Learn (optional)", for: .normal)
        toggleButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        toggleButton.contentHorizontalAlignment = .leading
        toggleButton.addTarget(self, action: #selector(togglePreSummary), for: .touchUpInside)
        preSummaryStack.addArrangedSubview(toggleButton)

        let preSummaryHint = UILabel()
        preSummaryHint.text = "Before reviewing your notes, write down what you remember. This helps identify gaps in your understanding."
        preSummaryHint.font = .preferredFont(forTextStyle: .caption1)
        preSummaryHint.textColor = .secondaryLabel
        preSummaryHint.numberOfLines = 0
        preSummaryHint.tag = 100
        preSummaryHint.isHidden = true
        preSummaryStack.addArrangedSubview(preSummaryHint)

        preSummaryTextView.font = .preferredFont(forTextStyle: .body)
        preSummaryTextView.layer.cornerRadius = 8
        preSummaryTextView.layer.borderWidth = 1
        preSummaryTextView.layer.borderColor = UIColor.separator.cgColor
        preSummaryTextView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        preSummaryTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        preSummaryTextView.inputAccessoryView = toolbar
        preSummaryTextView.isHidden = true
        preSummaryTextView.tag = 101
        preSummaryStack.addArrangedSubview(preSummaryTextView)

        contentStack.addArrangedSubview(preSummaryStack)

        // Extract button
        extractButton.setTitle("Extract Concepts", for: .normal)
        extractButton.setTitleColor(.white, for: .normal)
        extractButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        extractButton.startColor = UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0)
        extractButton.endColor = UIColor(red: 0.4, green: 0.3, blue: 0.9, alpha: 1.0)
        extractButton.cornerRadius = 14
        extractButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        extractButton.addTarget(self, action: #selector(extractTapped), for: .touchUpInside)
        contentStack.addArrangedSubview(extractButton)

        NSLayoutConstraint.activate([
            sv.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sv.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            sv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sv.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentStack.topAnchor.constraint(equalTo: sv.topAnchor, constant: 20),
            contentStack.bottomAnchor.constraint(equalTo: sv.bottomAnchor, constant: -20),
            contentStack.leadingAnchor.constraint(equalTo: sv.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: sv.trailingAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: sv.widthAnchor, constant: -40)
        ])
    }

    // MARK: - Keyboard Handling

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let inset = keyboardFrame.height - view.safeAreaInsets.bottom
        scrollView.contentInset.bottom = inset
        scrollView.verticalScrollIndicatorInsets.bottom = inset
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func togglePreSummary() {
        let hint = preSummaryContainer.viewWithTag(100)
        let textView = preSummaryContainer.viewWithTag(101)
        let isHidden = textView?.isHidden ?? true
        hint?.isHidden = !isHidden
        textView?.isHidden = !isHidden
    }

    @objc private func extractTapped() {
        view.endEditing(true)

        let deckName = deckNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let notes = notesTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let preSummary = preSummaryTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        if deckName.isEmpty {
            Alert.showAlert(on: self, title: "Missing Deck Name", message: "Please enter a name for the deck.")
            return
        }
        if notes.isEmpty {
            Alert.showAlert(on: self, title: "Missing Notes", message: "Please paste your study materials.")
            return
        }

        loadingOverlay.show(in: view, message: "Extracting concepts...")

        let userPreSummary = (preSummary?.isEmpty == false) ? preSummary : nil

        Task {
            do {
                let result = try await aiService.extractConcepts(from: notes, userPreSummary: userPreSummary) { [weak self] status in
                    DispatchQueue.main.async {
                        self?.loadingOverlay.updateMessage(status)
                    }
                }

                await MainActor.run {
                    loadingOverlay.dismiss()
                    let reviewVC = ConceptReviewViewController()
                    reviewVC.deckName = result.deckTitle.isEmpty ? deckName : result.deckTitle
                    reviewVC.sourceDescription = result.sourceDescription
                    reviewVC.originalNotes = notes
                    reviewVC.enrichedConcepts = result.concepts
                    reviewVC.extractionReport = result.report
                    navigationController?.pushViewController(reviewVC, animated: true)
                }
            } catch {
                await MainActor.run {
                    loadingOverlay.dismiss()
                    Alert.showAlert(on: self, title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - UITextFieldDelegate

extension AIInputViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == deckNameTextField {
            notesTextView.becomeFirstResponder()
        }
        return true
    }
}
