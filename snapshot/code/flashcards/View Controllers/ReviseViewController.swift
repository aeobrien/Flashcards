import UIKit

class ReviseViewController: UIViewController {

    // MARK: - Properties

    var flashcards: [Flashcard] = []
    private var currentIndex = 0
    private var isShowingAnswer = false

    // MARK: - UI Elements

    private let progressLabel = UILabel()
    private let cardContainer = UIView()
    private let frontView = UIView()
    private let backView = UIView()
    private let questionLabel = UILabel()
    private let answerStack = UIStackView()
    private let nextButton = UIButton(type: .system)
    private let prevButton = UIButton(type: .system)
    private let tapHintLabel = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Revise"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
        setupUI()
        setupGestures()
        showCard()
    }

    // MARK: - Setup

    private func setupUI() {
        // Progress label
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.font = .preferredFont(forTextStyle: .caption1)
        progressLabel.textColor = .secondaryLabel
        progressLabel.textAlignment = .center
        view.addSubview(progressLabel)

        // Card container
        cardContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardContainer)

        // Front view (question)
        frontView.translatesAutoresizingMaskIntoConstraints = false
        frontView.backgroundColor = .secondarySystemBackground
        frontView.layer.cornerRadius = 16
        frontView.layer.cornerCurve = .continuous
        frontView.layer.shadowColor = UIColor.black.cgColor
        frontView.layer.shadowOpacity = 0.1
        frontView.layer.shadowOffset = CGSize(width: 0, height: 2)
        frontView.layer.shadowRadius = 6
        cardContainer.addSubview(frontView)

        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        questionLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        questionLabel.textColor = .label
        questionLabel.numberOfLines = 0
        questionLabel.textAlignment = .center
        frontView.addSubview(questionLabel)

        tapHintLabel.translatesAutoresizingMaskIntoConstraints = false
        tapHintLabel.text = "Tap to reveal answer"
        tapHintLabel.font = .preferredFont(forTextStyle: .caption1)
        tapHintLabel.textColor = .tertiaryLabel
        tapHintLabel.textAlignment = .center
        frontView.addSubview(tapHintLabel)

        // Back view (answer)
        backView.translatesAutoresizingMaskIntoConstraints = false
        backView.backgroundColor = .secondarySystemBackground
        backView.layer.cornerRadius = 16
        backView.layer.cornerCurve = .continuous
        backView.layer.shadowColor = UIColor.black.cgColor
        backView.layer.shadowOpacity = 0.1
        backView.layer.shadowOffset = CGSize(width: 0, height: 2)
        backView.layer.shadowRadius = 6
        backView.isHidden = true
        cardContainer.addSubview(backView)

        let backScrollView = UIScrollView()
        backScrollView.translatesAutoresizingMaskIntoConstraints = false
        backView.addSubview(backScrollView)

        answerStack.translatesAutoresizingMaskIntoConstraints = false
        answerStack.axis = .vertical
        answerStack.spacing = 8
        backScrollView.addSubview(answerStack)

        // Navigation buttons
        let buttonStack = UIStackView()
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .horizontal
        buttonStack.spacing = 20
        buttonStack.distribution = .fillEqually
        view.addSubview(buttonStack)

        prevButton.setTitle("Previous", for: .normal)
        prevButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        prevButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(prevButton)

        nextButton.setTitle("Next", for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        buttonStack.addArrangedSubview(nextButton)

        NSLayoutConstraint.activate([
            progressLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            cardContainer.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 20),
            cardContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cardContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cardContainer.bottomAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -20),

            frontView.topAnchor.constraint(equalTo: cardContainer.topAnchor),
            frontView.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor),
            frontView.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
            frontView.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor),

            questionLabel.centerYAnchor.constraint(equalTo: frontView.centerYAnchor, constant: -12),
            questionLabel.leadingAnchor.constraint(equalTo: frontView.leadingAnchor, constant: 24),
            questionLabel.trailingAnchor.constraint(equalTo: frontView.trailingAnchor, constant: -24),

            tapHintLabel.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 20),
            tapHintLabel.centerXAnchor.constraint(equalTo: frontView.centerXAnchor),

            backView.topAnchor.constraint(equalTo: cardContainer.topAnchor),
            backView.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor),
            backView.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
            backView.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor),

            backScrollView.topAnchor.constraint(equalTo: backView.topAnchor, constant: 24),
            backScrollView.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -24),
            backScrollView.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 24),
            backScrollView.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -24),

            answerStack.topAnchor.constraint(equalTo: backScrollView.topAnchor),
            answerStack.bottomAnchor.constraint(equalTo: backScrollView.bottomAnchor),
            answerStack.leadingAnchor.constraint(equalTo: backScrollView.leadingAnchor),
            answerStack.trailingAnchor.constraint(equalTo: backScrollView.trailingAnchor),
            answerStack.widthAnchor.constraint(equalTo: backScrollView.widthAnchor),

            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        cardContainer.addGestureRecognizer(tapGesture)

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(nextTapped))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(prevTapped))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }

    // MARK: - Card Display

    private func showCard() {
        guard currentIndex < flashcards.count else { return }

        let flashcard = flashcards[currentIndex]
        isShowingAnswer = false

        progressLabel.text = "Card \(currentIndex + 1) of \(flashcards.count)"
        questionLabel.text = flashcard.frontLabel ?? "No question"

        // Reset to front
        frontView.isHidden = false
        backView.isHidden = true

        // Build answer content
        answerStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let questionHeader = UILabel()
        questionHeader.text = flashcard.frontLabel ?? ""
        questionHeader.font = .systemFont(ofSize: 18, weight: .semibold)
        questionHeader.textColor = .label
        questionHeader.numberOfLines = 0
        answerStack.addArrangedSubview(questionHeader)

        let separator = UIView()
        separator.backgroundColor = .separator
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        answerStack.addArrangedSubview(separator)
        answerStack.setCustomSpacing(12, after: separator)

        let bullets = flashcard.bulletPoints
        if !bullets.isEmpty {
            let keyPointsLabel = UILabel()
            keyPointsLabel.text = "Key Points"
            keyPointsLabel.font = .preferredFont(forTextStyle: .caption1)
            keyPointsLabel.textColor = .secondaryLabel
            answerStack.addArrangedSubview(keyPointsLabel)

            for point in bullets {
                let pointLabel = UILabel()
                pointLabel.text = "• \(point)"
                pointLabel.font = .preferredFont(forTextStyle: .body)
                pointLabel.textColor = .label
                pointLabel.numberOfLines = 0
                answerStack.addArrangedSubview(pointLabel)
            }
        } else if let desc = flashcard.backDescription, !desc.isEmpty {
            let descLabel = UILabel()
            descLabel.text = desc
            descLabel.font = .preferredFont(forTextStyle: .body)
            descLabel.textColor = .label
            descLabel.numberOfLines = 0
            answerStack.addArrangedSubview(descLabel)
        }

        updateNavButtons()
    }

    private func flipCard() {
        let fromView = isShowingAnswer ? backView : frontView
        let toView = isShowingAnswer ? frontView : backView

        let direction: UIView.AnimationOptions = isShowingAnswer ? .transitionFlipFromLeft : .transitionFlipFromRight

        UIView.transition(from: fromView, to: toView, duration: 0.4, options: [direction, .showHideTransitionViews])

        isShowingAnswer.toggle()
    }

    private func updateNavButtons() {
        prevButton.isEnabled = currentIndex > 0
        prevButton.alpha = currentIndex > 0 ? 1.0 : 0.3

        let isLast = currentIndex >= flashcards.count - 1
        nextButton.setTitle(isLast ? "Done" : "Next", for: .normal)
    }

    // MARK: - Actions

    @objc private func cardTapped() {
        flipCard()
    }

    @objc private func prevTapped() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        showCard()
    }

    @objc private func nextTapped() {
        if currentIndex >= flashcards.count - 1 {
            dismiss(animated: true)
            return
        }
        currentIndex += 1
        showCard()
    }

    @objc private func doneTapped() {
        dismiss(animated: true)
    }
}
