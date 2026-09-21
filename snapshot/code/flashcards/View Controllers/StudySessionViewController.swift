import UIKit

class StudySessionViewController: UIViewController {

    // MARK: - Properties

    var deck: Deck?
    var group: Group?
    var flashcards: [Flashcard] = []
    var isEarlyPractice: Bool = false

    private var currentCardIndex = 0
    private var userAnswers: [(flashcard: Flashcard, answer: String, confidence: Int16, hintCount: Int)] = []
    private var isRecording = false
    private var currentHintCount = 0

    private let schedulingService = SchedulingService(context: AppDelegate.getContext())
    private let studySessionService = StudySessionService(context: AppDelegate.getContext())
    private let transcriptionService = TranscriptionService.shared
    private let gradingService = AIGradingService()

    private var studySession: StudySession?
    private let loadingOverlay = LoadingOverlayView()

    // Input mode
    private enum InputMode {
        case voice, text
    }
    private var inputMode: InputMode = .voice

    // MARK: - UI Elements

    private let endSessionButton = UIButton(type: .system)
    private let earlyPracticeBanner = UILabel()
    private let progressBar = UIProgressView(progressViewStyle: .default)
    private let progressLabel = UILabel()
    private let questionCard = UIView()
    private let questionLabel = UILabel()
    private let constraintsLabel = UILabel()
    private let hintButton = UIButton(type: .system)

    // Input mode toggle
    private let inputModeToggle = UISegmentedControl(items: ["Voice", "Text"])

    // Voice input
    private let microphoneButton = MicrophoneButton(frame: .zero)
    private let reRecordButton = UIButton(type: .system)

    // Text input
    private let textInputView = UITextView()

    // Shared
    private let transcriptionPreview = UITextView()
    private let submitButton = GradientButton(frame: .zero)

    // Confidence picker
    private let confidenceContainer = UIStackView()
    private let confidenceLabel = UILabel()
    private var pendingAnswer: String?
    private var pendingConfidence: Int16 = 0

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = .systemBackground
        setupUI()
        setupActions()
        startSession()
    }

    // MARK: - Setup

    private func setupUI() {
        // End session button
        endSessionButton.translatesAutoresizingMaskIntoConstraints = false
        endSessionButton.setTitle("End Session", for: .normal)
        endSessionButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        endSessionButton.setTitleColor(.systemRed, for: .normal)
        view.addSubview(endSessionButton)

        // Early practice banner
        earlyPracticeBanner.translatesAutoresizingMaskIntoConstraints = false
        earlyPracticeBanner.text = "Early practice — scheduling not affected"
        earlyPracticeBanner.font = .preferredFont(forTextStyle: .caption2)
        earlyPracticeBanner.textColor = .systemOrange
        earlyPracticeBanner.textAlignment = .center
        earlyPracticeBanner.isHidden = !isEarlyPractice
        view.addSubview(earlyPracticeBanner)

        // Progress bar
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.progressTintColor = .systemBlue
        view.addSubview(progressBar)

        // Progress label
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.font = .preferredFont(forTextStyle: .caption1)
        progressLabel.textColor = .secondaryLabel
        progressLabel.textAlignment = .center
        view.addSubview(progressLabel)

        // Question card
        questionCard.translatesAutoresizingMaskIntoConstraints = false
        questionCard.backgroundColor = .secondarySystemBackground
        questionCard.layer.cornerRadius = 16
        questionCard.layer.cornerCurve = .continuous
        questionCard.layer.shadowColor = UIColor.black.cgColor
        questionCard.layer.shadowOpacity = 0.1
        questionCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        questionCard.layer.shadowRadius = 6
        view.addSubview(questionCard)

        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        questionLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        questionLabel.textColor = .label
        questionLabel.numberOfLines = 0
        questionLabel.textAlignment = .center
        questionCard.addSubview(questionLabel)

        constraintsLabel.translatesAutoresizingMaskIntoConstraints = false
        constraintsLabel.font = .italicSystemFont(ofSize: 14)
        constraintsLabel.textColor = .secondaryLabel
        constraintsLabel.numberOfLines = 0
        constraintsLabel.textAlignment = .center
        constraintsLabel.isHidden = true
        questionCard.addSubview(constraintsLabel)

        // Hint button
        hintButton.translatesAutoresizingMaskIntoConstraints = false
        hintButton.setTitle("Need a hint?", for: .normal)
        hintButton.titleLabel?.font = .preferredFont(forTextStyle: .caption1)
        hintButton.setTitleColor(.systemTeal, for: .normal)
        view.addSubview(hintButton)

        // Input mode toggle
        inputModeToggle.translatesAutoresizingMaskIntoConstraints = false
        inputModeToggle.selectedSegmentIndex = 0
        view.addSubview(inputModeToggle)

        // Microphone button
        microphoneButton.translatesAutoresizingMaskIntoConstraints = false
        microphoneButton.setState(.idle)
        view.addSubview(microphoneButton)

        // Re-record button
        reRecordButton.translatesAutoresizingMaskIntoConstraints = false
        reRecordButton.setTitle("Re-record", for: .normal)
        reRecordButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        reRecordButton.isHidden = true
        view.addSubview(reRecordButton)

        // Text input view
        textInputView.translatesAutoresizingMaskIntoConstraints = false
        textInputView.font = .preferredFont(forTextStyle: .body)
        textInputView.textColor = .label
        textInputView.backgroundColor = .tertiarySystemBackground
        textInputView.layer.cornerRadius = 12
        textInputView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textInputView.isHidden = true
        textInputView.delegate = self
        view.addSubview(textInputView)

        // Transcription preview (used in voice mode)
        transcriptionPreview.translatesAutoresizingMaskIntoConstraints = false
        transcriptionPreview.isEditable = true
        transcriptionPreview.font = .preferredFont(forTextStyle: .body)
        transcriptionPreview.textColor = .label
        transcriptionPreview.backgroundColor = .tertiarySystemBackground
        transcriptionPreview.layer.cornerRadius = 12
        transcriptionPreview.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        transcriptionPreview.text = "Tap the microphone to record your answer..."
        transcriptionPreview.textColor = .placeholderText
        transcriptionPreview.delegate = self
        view.addSubview(transcriptionPreview)

        // Submit button
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.setTitle("Submit & Next", for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        submitButton.startColor = UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0)
        submitButton.endColor = UIColor(red: 0.4, green: 0.3, blue: 0.9, alpha: 1.0)
        submitButton.cornerRadius = 14
        submitButton.isEnabled = false
        submitButton.alpha = 0.5
        view.addSubview(submitButton)

        // Confidence picker (hidden by default)
        confidenceContainer.translatesAutoresizingMaskIntoConstraints = false
        confidenceContainer.axis = .vertical
        confidenceContainer.spacing = 8
        confidenceContainer.isHidden = true
        view.addSubview(confidenceContainer)

        confidenceLabel.text = "How confident are you?"
        confidenceLabel.font = .systemFont(ofSize: 16, weight: .medium)
        confidenceLabel.textAlignment = .center
        confidenceContainer.addArrangedSubview(confidenceLabel)

        let buttonsStack = UIStackView()
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 12
        buttonsStack.distribution = .fillEqually

        let lowBtn = createConfidenceButton(title: "Low", tag: 1, color: .systemRed)
        let medBtn = createConfidenceButton(title: "Medium", tag: 2, color: .systemYellow)
        let highBtn = createConfidenceButton(title: "High", tag: 3, color: .systemGreen)
        buttonsStack.addArrangedSubview(lowBtn)
        buttonsStack.addArrangedSubview(medBtn)
        buttonsStack.addArrangedSubview(highBtn)
        confidenceContainer.addArrangedSubview(buttonsStack)

        let bannerTopConstraint = isEarlyPractice
            ? earlyPracticeBanner.topAnchor.constraint(equalTo: endSessionButton.bottomAnchor, constant: 2)
            : earlyPracticeBanner.topAnchor.constraint(equalTo: endSessionButton.bottomAnchor, constant: 0)

        NSLayoutConstraint.activate([
            endSessionButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            endSessionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            bannerTopConstraint,
            earlyPracticeBanner.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            progressBar.topAnchor.constraint(equalTo: earlyPracticeBanner.bottomAnchor, constant: 4),
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            progressLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 8),
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            questionCard.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 16),
            questionCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            questionCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            questionCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),

            questionLabel.topAnchor.constraint(equalTo: questionCard.topAnchor, constant: 16),
            questionLabel.leadingAnchor.constraint(equalTo: questionCard.leadingAnchor, constant: 16),
            questionLabel.trailingAnchor.constraint(equalTo: questionCard.trailingAnchor, constant: -16),

            constraintsLabel.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 8),
            constraintsLabel.leadingAnchor.constraint(equalTo: questionCard.leadingAnchor, constant: 16),
            constraintsLabel.trailingAnchor.constraint(equalTo: questionCard.trailingAnchor, constant: -16),
            constraintsLabel.bottomAnchor.constraint(equalTo: questionCard.bottomAnchor, constant: -16),

            hintButton.topAnchor.constraint(equalTo: questionCard.bottomAnchor, constant: 4),
            hintButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            inputModeToggle.topAnchor.constraint(equalTo: hintButton.bottomAnchor, constant: 8),
            inputModeToggle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            inputModeToggle.widthAnchor.constraint(equalToConstant: 160),

            microphoneButton.topAnchor.constraint(equalTo: inputModeToggle.bottomAnchor, constant: 12),
            microphoneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            microphoneButton.widthAnchor.constraint(equalToConstant: 72),
            microphoneButton.heightAnchor.constraint(equalToConstant: 72),

            transcriptionPreview.topAnchor.constraint(equalTo: microphoneButton.bottomAnchor, constant: 12),
            transcriptionPreview.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            transcriptionPreview.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            transcriptionPreview.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            transcriptionPreview.heightAnchor.constraint(lessThanOrEqualToConstant: 120),

            textInputView.topAnchor.constraint(equalTo: inputModeToggle.bottomAnchor, constant: 12),
            textInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textInputView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            textInputView.heightAnchor.constraint(lessThanOrEqualToConstant: 160),

            reRecordButton.topAnchor.constraint(equalTo: transcriptionPreview.bottomAnchor, constant: 8),
            reRecordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            submitButton.topAnchor.constraint(equalTo: reRecordButton.bottomAnchor, constant: 8),
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            submitButton.heightAnchor.constraint(equalToConstant: 50),

            confidenceContainer.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: 12),
            confidenceContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confidenceContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            confidenceContainer.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func createConfidenceButton(title: String, tag: Int, color: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.tag = tag
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        btn.backgroundColor = color.withAlphaComponent(0.15)
        btn.setTitleColor(color, for: .normal)
        btn.layer.cornerRadius = 10
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        btn.addTarget(self, action: #selector(confidenceTapped(_:)), for: .touchUpInside)
        return btn
    }

    private func setupActions() {
        microphoneButton.onTap = { [weak self] in
            self?.microphoneTapped()
        }
        reRecordButton.addTarget(self, action: #selector(reRecordTapped), for: .touchUpInside)
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        endSessionButton.addTarget(self, action: #selector(endSessionTapped), for: .touchUpInside)
        inputModeToggle.addTarget(self, action: #selector(inputModeChanged), for: .valueChanged)
        hintButton.addTarget(self, action: #selector(hintTapped), for: .touchUpInside)
    }

    // MARK: - Input Mode Toggle

    @objc private func inputModeChanged() {
        inputMode = inputModeToggle.selectedSegmentIndex == 0 ? .voice : .text
        updateInputModeUI()
    }

    private func updateInputModeUI() {
        switch inputMode {
        case .voice:
            microphoneButton.isHidden = false
            transcriptionPreview.isHidden = false
            reRecordButton.isHidden = (transcriptionPreview.textColor == .placeholderText)
            textInputView.isHidden = true
        case .text:
            microphoneButton.isHidden = true
            transcriptionPreview.isHidden = true
            reRecordButton.isHidden = true
            textInputView.isHidden = false
            textInputView.becomeFirstResponder()
        }
    }

    // MARK: - Session Flow

    private func startSession() {
        if flashcards.isEmpty {
            if let deck = deck {
                flashcards = schedulingService.fetchDueFlashcards(for: deck)
            } else if let group = group {
                flashcards = schedulingService.fetchDueFlashcards(for: group)
            }
        }

        guard !flashcards.isEmpty else {
            showNoDueCardsAlert()
            return
        }

        if let deck = deck {
            studySession = studySessionService.createSession(for: deck)
        } else if let group = group {
            studySession = studySessionService.createGroupSession(for: group)
        }

        if isEarlyPractice {
            studySession?.isEarlyPractice = true
            AppDelegate.shared.saveContext()
        }

        showCurrentCard()

        // Pre-load WhisperKit model in background so it's ready for first recording
        Task {
            if !transcriptionService.isModelReady {
                try? await transcriptionService.prepareModel()
            }
        }
    }

    private func showCurrentCard() {
        guard currentCardIndex < flashcards.count else {
            finishSession()
            return
        }

        let flashcard = flashcards[currentCardIndex]
        questionLabel.text = flashcard.frontLabel ?? "No question"

        // Show deck name for group sessions
        if group != nil, let deckName = flashcard.deck?.deckName {
            progressLabel.text = "Card \(currentCardIndex + 1) of \(flashcards.count) — \(deckName)"
        }

        // Show constraints if available
        let cardConstraints = flashcard.constraints
        if !cardConstraints.isEmpty {
            constraintsLabel.text = cardConstraints.map { "- \($0)" }.joined(separator: "\n")
            constraintsLabel.isHidden = false
        } else {
            constraintsLabel.isHidden = true
        }

        updateProgress()
        resetInputUI()
        currentHintCount = 0
        hintButton.setTitle("Need a hint?", for: .normal)
        hintButton.isEnabled = true
        confidenceContainer.isHidden = true
    }

    private func updateProgress() {
        let progress = Float(currentCardIndex) / Float(flashcards.count)
        progressBar.setProgress(progress, animated: true)
        if group == nil {
            progressLabel.text = "Card \(currentCardIndex + 1) of \(flashcards.count)"
        }
    }

    private func resetInputUI() {
        // Voice mode
        transcriptionPreview.text = "Tap the microphone to record your answer..."
        transcriptionPreview.textColor = .placeholderText
        transcriptionPreview.isEditable = true
        reRecordButton.isHidden = true
        microphoneButton.setState(.idle)

        // Text mode
        textInputView.text = ""

        // Shared
        submitButton.isEnabled = false
        submitButton.alpha = 0.5

        updateInputModeUI()
    }

    // MARK: - Hints

    @objc private func hintTapped() {
        guard currentCardIndex < flashcards.count else { return }
        let flashcard = flashcards[currentCardIndex]
        currentHintCount += 1

        if currentHintCount == 1 {
            // Mild hint: category/first letters of keywords
            let keywords = flashcard.gradingRubric?.mustContainKeywords ?? []
            if !keywords.isEmpty {
                let firstLetters = keywords.map { String($0.prefix(2)) + "..." }.joined(separator: ", ")
                hintButton.setTitle("Keywords start with: \(firstLetters)", for: .normal)
            } else if let concept = flashcard.concept?.name {
                hintButton.setTitle("Related to: \(concept)", for: .normal)
            } else {
                hintButton.setTitle("Think about the key terms.", for: .normal)
            }
        } else {
            // Stronger hint: one bullet point
            let bullets = flashcard.bulletPoints
            if let first = bullets.first {
                hintButton.setTitle("Key point: \(first)", for: .normal)
            } else {
                hintButton.setTitle("Review the question carefully.", for: .normal)
            }
            hintButton.isEnabled = false
        }

        hintButton.titleLabel?.numberOfLines = 0
        hintButton.titleLabel?.textAlignment = .center
    }

    // MARK: - Recording

    private func microphoneTapped() {
        if isRecording {
            stopRecording()
        } else {
            startRecordingFlow()
        }
    }

    private func startRecordingFlow() {
        Task {
            let permitted = await transcriptionService.requestMicrophonePermission()
            guard permitted else {
                await MainActor.run {
                    Alert.showAlert(on: self, title: "Microphone Access", message: "Please enable microphone access in Settings to record answers.")
                }
                return
            }

            if !transcriptionService.isModelReady {
                await MainActor.run {
                    microphoneButton.setState(.processing)
                }
                do {
                    try await transcriptionService.prepareModel()
                } catch {
                    await MainActor.run {
                        microphoneButton.setState(.idle)
                        Alert.showAlert(on: self, title: "Model Error", message: "Failed to load transcription model: \(error.localizedDescription)")
                    }
                    return
                }
            }

            await MainActor.run {
                do {
                    try transcriptionService.startRecording()
                    isRecording = true
                    microphoneButton.setState(.recording)
                    transcriptionPreview.text = "Recording... Tap stop when finished."
                    transcriptionPreview.textColor = .systemRed
                } catch {
                    Alert.showAlert(on: self, title: "Recording Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func stopRecording() {
        isRecording = false
        microphoneButton.setState(.processing)
        transcriptionPreview.text = "Transcribing..."
        transcriptionPreview.textColor = .secondaryLabel

        Task {
            do {
                let text = try await transcriptionService.stopRecordingAndTranscribe()
                await MainActor.run {
                    transcriptionPreview.text = text
                    transcriptionPreview.textColor = .label
                    microphoneButton.setState(.idle)
                    reRecordButton.isHidden = false
                    submitButton.isEnabled = true
                    submitButton.alpha = 1.0
                }
            } catch {
                await MainActor.run {
                    microphoneButton.setState(.idle)
                    transcriptionPreview.text = "Transcription failed. Tap to try again."
                    transcriptionPreview.textColor = .systemRed
                    Alert.showAlert(on: self, title: "Transcription Error", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func reRecordTapped() {
        resetInputUI()
    }

    @objc private func endSessionTapped() {
        if userAnswers.isEmpty {
            dismiss(animated: true)
            return
        }

        let alert = UIAlertController(
            title: "End Session Early?",
            message: "You've answered \(userAnswers.count) of \(flashcards.count) cards. End now and get your grades?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "End & Grade", style: .default) { [weak self] _ in
            self?.finishSession()
        })
        present(alert, animated: true)
    }

    @objc private func submitTapped() {
        let answer: String
        switch inputMode {
        case .voice:
            answer = transcriptionPreview.text ?? ""
            guard !answer.isEmpty, transcriptionPreview.textColor != .placeholderText else { return }
        case .text:
            answer = textInputView.text ?? ""
            guard !answer.isEmpty else { return }
        }

        view.endEditing(true)
        pendingAnswer = answer

        // Show confidence picker
        submitButton.isEnabled = false
        submitButton.alpha = 0.5
        confidenceContainer.isHidden = false
    }

    @objc private func confidenceTapped(_ sender: UIButton) {
        guard let answer = pendingAnswer else { return }
        let confidence = Int16(sender.tag) // 1=Low, 2=Medium, 3=High

        let flashcard = flashcards[currentCardIndex]
        userAnswers.append((flashcard: flashcard, answer: answer, confidence: confidence, hintCount: currentHintCount))

        pendingAnswer = nil
        confidenceContainer.isHidden = true
        currentCardIndex += 1
        showCurrentCard()
    }

    // MARK: - Finish & Grade

    private func finishSession() {
        loadingOverlay.show(in: view, message: "Grading your answers...")
        progressBar.setProgress(1.0, animated: true)

        Task {
            do {
                let gradingItems = userAnswers.map { item -> (question: String, constraints: [String], bulletPoints: [String], modelParagraph: String, gradingRubric: GradingRubric?, studentAnswer: String) in
                    (
                        question: item.flashcard.frontLabel ?? "",
                        constraints: item.flashcard.constraints,
                        bulletPoints: item.flashcard.bulletPoints,
                        modelParagraph: item.flashcard.modelParagraph ?? item.flashcard.backDescription ?? "",
                        gradingRubric: item.flashcard.gradingRubric,
                        studentAnswer: item.answer
                    )
                }

                let grades = try await gradingService.batchGrade(items: gradingItems)

                await MainActor.run {
                    applyGrades(grades)
                }
            } catch {
                await MainActor.run {
                    loadingOverlay.dismiss()
                    let fallbackGrades = userAnswers.map { _ in
                        GradingResponse(grade: 3, feedback: "Grading unavailable — default grade assigned.", bulletPointsHit: [])
                    }
                    applyGrades(fallbackGrades)
                }
            }
        }
    }

    private func applyGrades(_ grades: [GradingResponse]) {
        guard let session = studySession else { return }

        for (index, gradeResult) in grades.enumerated() {
            guard index < userAnswers.count else { break }
            let item = userAnswers[index]
            let grade = Int16(max(1, min(5, gradeResult.grade)))

            // Record session response with confidence
            let response = studySessionService.addResponse(
                to: session,
                flashcard: item.flashcard,
                userAnswer: item.answer,
                grade: grade,
                feedback: gradeResult.feedback
            )
            response.confidence = item.confidence

            // Update Leitner box — skip for early practice sessions
            if !isEarlyPractice {
                _ = schedulingService.processGrade(for: item.flashcard, grade: grade)
            }
        }

        studySessionService.completeSession(session)

        NotificationCenter.default.post(name: .didCompleteStudySession, object: nil)
        NotificationCenter.default.post(name: .didUpdateFlashcards, object: nil)
        NotificationCenter.default.post(name: .didUpdateDecks, object: nil)

        loadingOverlay.dismiss { [weak self] in
            self?.showResults(session: session, grades: grades)
        }
    }

    private func showResults(session: StudySession, grades: [GradingResponse]) {
        let resultsVC = SessionResultsViewController()
        resultsVC.studySession = session
        resultsVC.userAnswers = userAnswers.map { (flashcard: $0.flashcard, answer: $0.answer) }
        resultsVC.gradingResults = grades
        resultsVC.confidenceValues = userAnswers.map { $0.confidence }
        resultsVC.isGroupSession = (group != nil)
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.pushViewController(resultsVC, animated: true)
    }

    private func showNoDueCardsAlert() {
        let message: String
        if let deck = deck {
            let nextDate = schedulingService.nextReviewDate(for: deck)
            if let next = nextDate {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .full
                let relative = formatter.localizedString(for: next, relativeTo: Date())
                message = "All caught up! Next review \(relative)."
            } else {
                message = "No cards are due for review."
            }
        } else {
            message = "No cards are due for review across this group."
        }

        Alert.showAlert(on: self, title: "All Caught Up!", message: message, actionTitle: "OK") { [weak self] in
            self?.dismiss(animated: true)
        }
    }
}

// MARK: - UITextViewDelegate

extension StudySessionViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        if textView == textInputView {
            let hasText = !(textView.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            submitButton.isEnabled = hasText
            submitButton.alpha = hasText ? 1.0 : 0.5
        } else if textView == transcriptionPreview && textView.textColor != .placeholderText {
            // User edited transcription — enable submit if has content
            let hasText = !(textView.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            submitButton.isEnabled = hasText
            submitButton.alpha = hasText ? 1.0 : 0.5
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == transcriptionPreview && textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }
}
