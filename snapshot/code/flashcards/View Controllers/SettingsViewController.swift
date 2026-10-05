import UIKit

class SettingsViewController: UIViewController {

    // MARK: - UI Elements

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let apiKeyTextField = UITextField()
    private let apiKeyStatusLabel = UILabel()
    private let saveKeyButton = UIButton(type: .system)
    private let deleteKeyButton = UIButton(type: .system)

    private let whisperStatusLabel = UILabel()
    private let downloadWhisperButton = UIButton(type: .system)

    private let conceptPromptTextView = UITextView()
    private let conceptPromptStatusLabel = UILabel()
    private let cardGenPromptTextView = UITextView()
    private let cardGenPromptStatusLabel = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        setupUI()
        updateAPIKeyStatus()
        updateWhisperStatus()
        loadPrompts()
    }

    // MARK: - Setup

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        // API Key Section
        let apiHeader = createSectionHeader("Anthropic API Key")
        contentStack.addArrangedSubview(apiHeader)

        apiKeyTextField.placeholder = "sk-ant-..."
        apiKeyTextField.isSecureTextEntry = true
        apiKeyTextField.borderStyle = .roundedRect
        apiKeyTextField.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        apiKeyTextField.autocapitalizationType = .none
        apiKeyTextField.autocorrectionType = .no
        contentStack.addArrangedSubview(apiKeyTextField)

        apiKeyStatusLabel.font = .preferredFont(forTextStyle: .caption1)
        apiKeyStatusLabel.textColor = .secondaryLabel
        contentStack.addArrangedSubview(apiKeyStatusLabel)

        let keyButtonStack = UIStackView()
        keyButtonStack.axis = .horizontal
        keyButtonStack.spacing = 12
        keyButtonStack.distribution = .fillEqually

        saveKeyButton.setTitle("Save Key", for: .normal)
        saveKeyButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        saveKeyButton.backgroundColor = .systemBlue
        saveKeyButton.setTitleColor(.white, for: .normal)
        saveKeyButton.layer.cornerRadius = 8
        saveKeyButton.addTarget(self, action: #selector(saveKeyTapped), for: .touchUpInside)
        saveKeyButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        keyButtonStack.addArrangedSubview(saveKeyButton)

        deleteKeyButton.setTitle("Delete Key", for: .normal)
        deleteKeyButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        deleteKeyButton.backgroundColor = .systemRed.withAlphaComponent(0.1)
        deleteKeyButton.setTitleColor(.systemRed, for: .normal)
        deleteKeyButton.layer.cornerRadius = 8
        deleteKeyButton.addTarget(self, action: #selector(deleteKeyTapped), for: .touchUpInside)
        keyButtonStack.addArrangedSubview(deleteKeyButton)

        contentStack.addArrangedSubview(keyButtonStack)

        addSeparator()

        // WhisperKit Section
        let whisperHeader = createSectionHeader("Voice Transcription Model")
        contentStack.addArrangedSubview(whisperHeader)

        whisperStatusLabel.font = .preferredFont(forTextStyle: .body)
        whisperStatusLabel.numberOfLines = 0
        contentStack.addArrangedSubview(whisperStatusLabel)

        downloadWhisperButton.setTitle("Download Model", for: .normal)
        downloadWhisperButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        downloadWhisperButton.backgroundColor = .systemBlue
        downloadWhisperButton.setTitleColor(.white, for: .normal)
        downloadWhisperButton.layer.cornerRadius = 8
        downloadWhisperButton.addTarget(self, action: #selector(downloadWhisperTapped), for: .touchUpInside)
        downloadWhisperButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        contentStack.addArrangedSubview(downloadWhisperButton)

        addSeparator()

        // Concept Extraction Prompt Section
        let conceptHeader = createSectionHeader("Concept Extraction Prompt")
        contentStack.addArrangedSubview(conceptHeader)

        let conceptDesc = UILabel()
        conceptDesc.text = "This prompt tells the AI how to extract concepts from your study notes."
        conceptDesc.font = .preferredFont(forTextStyle: .caption1)
        conceptDesc.textColor = .secondaryLabel
        conceptDesc.numberOfLines = 0
        contentStack.addArrangedSubview(conceptDesc)

        configurePromptTextView(conceptPromptTextView)
        contentStack.addArrangedSubview(conceptPromptTextView)

        conceptPromptStatusLabel.font = .preferredFont(forTextStyle: .caption1)
        conceptPromptStatusLabel.textColor = .secondaryLabel
        contentStack.addArrangedSubview(conceptPromptStatusLabel)

        let conceptButtonStack = createPromptButtonStack(
            saveAction: #selector(saveConceptPromptTapped),
            resetAction: #selector(resetConceptPromptTapped)
        )
        contentStack.addArrangedSubview(conceptButtonStack)

        addSeparator()

        // Card Generation Prompt Section
        let cardGenHeader = createSectionHeader("Card Generation Prompt")
        contentStack.addArrangedSubview(cardGenHeader)

        let cardGenDesc = UILabel()
        cardGenDesc.text = "This prompt tells the AI how to generate flashcards from the extracted concepts."
        cardGenDesc.font = .preferredFont(forTextStyle: .caption1)
        cardGenDesc.textColor = .secondaryLabel
        cardGenDesc.numberOfLines = 0
        contentStack.addArrangedSubview(cardGenDesc)

        configurePromptTextView(cardGenPromptTextView)
        contentStack.addArrangedSubview(cardGenPromptTextView)

        cardGenPromptStatusLabel.font = .preferredFont(forTextStyle: .caption1)
        cardGenPromptStatusLabel.textColor = .secondaryLabel
        contentStack.addArrangedSubview(cardGenPromptStatusLabel)

        let cardGenButtonStack = createPromptButtonStack(
            saveAction: #selector(saveCardGenPromptTapped),
            resetAction: #selector(resetCardGenPromptTapped)
        )
        contentStack.addArrangedSubview(cardGenButtonStack)

        addSeparator()

        // Debug Section
        let debugHeader = createSectionHeader("Debug")
        contentStack.addArrangedSubview(debugHeader)

        let viewLogsButton = UIButton(type: .system)
        viewLogsButton.setTitle("View Debug Logs", for: .normal)
        viewLogsButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        viewLogsButton.backgroundColor = .secondarySystemBackground
        viewLogsButton.setTitleColor(.label, for: .normal)
        viewLogsButton.layer.cornerRadius = 8
        viewLogsButton.addTarget(self, action: #selector(viewLogsTapped), for: .touchUpInside)
        viewLogsButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        contentStack.addArrangedSubview(viewLogsButton)

        if DebugLogService.shared.hasRecoveryFile {
            let recoverButton = UIButton(type: .system)
            let dateStr: String
            if let date = DebugLogService.shared.recoveryFileDate {
                let fmt = DateFormatter()
                fmt.dateStyle = .short
                fmt.timeStyle = .short
                dateStr = fmt.string(from: date)
            } else {
                dateStr = "unknown date"
            }
            recoverButton.setTitle("Recover Cards (\(dateStr))", for: .normal)
            recoverButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            recoverButton.backgroundColor = .systemOrange.withAlphaComponent(0.15)
            recoverButton.setTitleColor(.systemOrange, for: .normal)
            recoverButton.layer.cornerRadius = 8
            recoverButton.addTarget(self, action: #selector(recoverCardsTapped), for: .touchUpInside)
            recoverButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
            contentStack.addArrangedSubview(recoverButton)
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    private func createSectionHeader(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        return label
    }

    private func addSeparator() {
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        contentStack.addArrangedSubview(separator)
    }

    private func configurePromptTextView(_ textView: UITextView) {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 180).isActive = true

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [UIBarButtonItem.flexibleSpace(), done]
        textView.inputAccessoryView = toolbar
    }

    private func createPromptButtonStack(saveAction: Selector, resetAction: Selector) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually

        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save Prompt", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 8
        saveButton.addTarget(self, action: saveAction, for: .touchUpInside)
        saveButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        stack.addArrangedSubview(saveButton)

        let resetButton = UIButton(type: .system)
        resetButton.setTitle("Reset to Default", for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        resetButton.backgroundColor = .systemOrange.withAlphaComponent(0.1)
        resetButton.setTitleColor(.systemOrange, for: .normal)
        resetButton.layer.cornerRadius = 8
        resetButton.addTarget(self, action: resetAction, for: .touchUpInside)
        stack.addArrangedSubview(resetButton)

        return stack
    }

    // MARK: - Prompt Management

    private func loadPrompts() {
        conceptPromptTextView.text = ClaudePromptTemplates.conceptExtractionSystem
        cardGenPromptTextView.text = ClaudePromptTemplates.cardGenerationSystem
        updatePromptStatuses()
    }

    private func updatePromptStatuses() {
        conceptPromptStatusLabel.text = ClaudePromptTemplates.hasCustomConceptExtractionPrompt
            ? "Using custom prompt"
            : "Using default prompt"
        conceptPromptStatusLabel.textColor = ClaudePromptTemplates.hasCustomConceptExtractionPrompt
            ? .systemBlue
            : .secondaryLabel

        cardGenPromptStatusLabel.text = ClaudePromptTemplates.hasCustomCardGenerationPrompt
            ? "Using custom prompt"
            : "Using default prompt"
        cardGenPromptStatusLabel.textColor = ClaudePromptTemplates.hasCustomCardGenerationPrompt
            ? .systemBlue
            : .secondaryLabel
    }

    @objc private func saveConceptPromptTapped() {
        let text = conceptPromptTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else {
            Alert.showAlert(on: self, title: "Empty Prompt", message: "The prompt cannot be empty.")
            return
        }
        ClaudePromptTemplates.saveConceptExtractionPrompt(text)
        updatePromptStatuses()
        ToastManager.shared.showToast(on: self, message: "Concept extraction prompt saved!")
    }

    @objc private func resetConceptPromptTapped() {
        ClaudePromptTemplates.saveConceptExtractionPrompt(nil)
        conceptPromptTextView.text = ClaudePromptTemplates.defaultConceptExtractionSystem
        updatePromptStatuses()
        ToastManager.shared.showToast(on: self, message: "Reset to default prompt")
    }

    @objc private func saveCardGenPromptTapped() {
        let text = cardGenPromptTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else {
            Alert.showAlert(on: self, title: "Empty Prompt", message: "The prompt cannot be empty.")
            return
        }
        ClaudePromptTemplates.saveCardGenerationPrompt(text)
        updatePromptStatuses()
        ToastManager.shared.showToast(on: self, message: "Card generation prompt saved!")
    }

    @objc private func resetCardGenPromptTapped() {
        ClaudePromptTemplates.saveCardGenerationPrompt(nil)
        cardGenPromptTextView.text = ClaudePromptTemplates.defaultCardGenerationSystem
        updatePromptStatuses()
        ToastManager.shared.showToast(on: self, message: "Reset to default prompt")
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - API Key Management

    private func updateAPIKeyStatus() {
        if KeychainHelper.shared.anthropicAPIKey != nil {
            apiKeyStatusLabel.text = "API key is saved securely in Keychain."
            apiKeyStatusLabel.textColor = .systemGreen
            deleteKeyButton.isEnabled = true
        } else {
            apiKeyStatusLabel.text = "No API key configured."
            apiKeyStatusLabel.textColor = .secondaryLabel
            deleteKeyButton.isEnabled = false
        }
    }

    @objc private func saveKeyTapped() {
        let key = apiKeyTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !key.isEmpty else {
            Alert.showAlert(on: self, title: "Empty Key", message: "Please enter your Anthropic API key.")
            return
        }

        KeychainHelper.shared.anthropicAPIKey = key
        apiKeyTextField.text = ""
        updateAPIKeyStatus()
        ToastManager.shared.showToast(on: self, message: "API key saved!")
    }

    @objc private func deleteKeyTapped() {
        KeychainHelper.shared.anthropicAPIKey = nil
        updateAPIKeyStatus()
        ToastManager.shared.showToast(on: self, message: "API key deleted")
    }

    // MARK: - WhisperKit Management

    private func updateWhisperStatus() {
        let service = TranscriptionService.shared
        switch service.state {
        case .notDownloaded:
            if service.isModelCached {
                whisperStatusLabel.text = "Model downloaded, not loaded into memory yet"
                whisperStatusLabel.textColor = .systemOrange
                downloadWhisperButton.isEnabled = true
                downloadWhisperButton.setTitle("Load Model", for: .normal)
            } else {
                whisperStatusLabel.text = "Model not downloaded (~150MB)"
                whisperStatusLabel.textColor = .secondaryLabel
                downloadWhisperButton.isEnabled = true
                downloadWhisperButton.setTitle("Download Model", for: .normal)
            }
        case .downloading(let progress):
            whisperStatusLabel.text = "Downloading... \(Int(progress * 100))%"
            whisperStatusLabel.textColor = .systemBlue
            downloadWhisperButton.isEnabled = false
            downloadWhisperButton.setTitle("Downloading...", for: .normal)
        case .ready:
            whisperStatusLabel.text = "Model ready"
            whisperStatusLabel.textColor = .systemGreen
            downloadWhisperButton.isEnabled = false
            downloadWhisperButton.setTitle("Downloaded", for: .normal)
        case .error(let message):
            whisperStatusLabel.text = "Error: \(message)"
            whisperStatusLabel.textColor = .systemRed
            downloadWhisperButton.isEnabled = true
            downloadWhisperButton.setTitle("Retry Download", for: .normal)
        }
    }

    @objc private func downloadWhisperTapped() {
        downloadWhisperButton.isEnabled = false
        downloadWhisperButton.setTitle("Downloading...", for: .normal)
        whisperStatusLabel.text = "Downloading model..."
        whisperStatusLabel.textColor = .systemBlue

        Task {
            do {
                try await TranscriptionService.shared.prepareModel()
                await MainActor.run {
                    updateWhisperStatus()
                    ToastManager.shared.showToast(on: self, message: "Model downloaded!")
                }
            } catch {
                await MainActor.run {
                    updateWhisperStatus()
                    Alert.showAlert(on: self, title: "Download Failed", message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Debug

    @objc private func viewLogsTapped() {
        let logVC = DebugLogViewController()
        navigationController?.pushViewController(logVC, animated: true)
    }

    @objc private func recoverCardsTapped() {
        guard let recovery = DebugLogService.shared.loadRecoveryData() else {
            Alert.showAlert(on: self, title: "Recovery Failed", message: "Could not read recovery file.")
            return
        }

        let cardCount = recovery.cards.count
        let alert = UIAlertController(
            title: "Recover \(cardCount) Cards?",
            message: "Deck: \(recovery.deckName)\nSaved: \(DateFormatter.localizedString(from: recovery.savedAt, dateStyle: .short, timeStyle: .short))",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Recover", style: .default) { [weak self] _ in
            self?.performRecovery(recovery)
        })
        present(alert, animated: true)
    }

    private func performRecovery(_ recovery: CardRecoveryData) {
        let cards = recovery.cards.map { $0.toGeneratedFlashcard() }
        let concepts = recovery.concepts.map { $0.toEnrichedConcept() }

        let cardReviewVC = CardReviewViewController()
        cardReviewVC.deckName = recovery.deckName
        cardReviewVC.sourceDescription = recovery.sourceDescription
        cardReviewVC.enrichedConcepts = concepts
        cardReviewVC.generatedCards = cards
        navigationController?.pushViewController(cardReviewVC, animated: true)
    }

    // MARK: - Actions

    @objc private func doneTapped() {
        dismiss(animated: true)
    }
}
