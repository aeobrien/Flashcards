import UIKit

class ResultCardTableViewCell: UITableViewCell {

    private let cardView = UIView()
    private let questionLabel = UILabel()
    private let gradeBadge = UILabel()
    private let verificationBadge = UILabel()
    private let expandedContainer = UIStackView()

    private let userAnswerLabel = UILabel()
    private let feedbackLabel = UILabel()
    private let bulletPointsStack = UIStackView()
    private let sourceRefsLabel = UILabel()
    private let backgroundContextStack = UIStackView()
    private let sourceRefsContainer = UIStackView()
    private let backgroundContextContainer = UIStackView()

    private(set) var isExpanded = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear

        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 12
        cardView.layer.cornerCurve = .continuous
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        // Outer stack holds header + expandable detail
        let outerStack = UIStackView()
        outerStack.axis = .vertical
        outerStack.spacing = 0
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(outerStack)

        // Header row
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 8
        headerStack.isLayoutMarginsRelativeArrangement = true
        headerStack.layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)

        questionLabel.font = .preferredFont(forTextStyle: .body)
        questionLabel.textColor = .label
        questionLabel.numberOfLines = 0
        questionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerStack.addArrangedSubview(questionLabel)

        verificationBadge.text = " ⚠ "
        verificationBadge.font = .systemFont(ofSize: 14, weight: .bold)
        verificationBadge.textColor = .systemOrange
        verificationBadge.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
        verificationBadge.layer.cornerRadius = 10
        verificationBadge.layer.masksToBounds = true
        verificationBadge.setContentHuggingPriority(.required, for: .horizontal)
        verificationBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
        verificationBadge.isHidden = true
        headerStack.addArrangedSubview(verificationBadge)

        gradeBadge.font = .systemFont(ofSize: 14, weight: .bold)
        gradeBadge.textAlignment = .center
        gradeBadge.layer.cornerRadius = 12
        gradeBadge.layer.masksToBounds = true
        gradeBadge.setContentHuggingPriority(.required, for: .horizontal)
        gradeBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
        headerStack.addArrangedSubview(gradeBadge)

        outerStack.addArrangedSubview(headerStack)

        // Expanded detail — UIStackView collapses this when hidden
        expandedContainer.axis = .vertical
        expandedContainer.spacing = 4
        expandedContainer.isHidden = true
        expandedContainer.isLayoutMarginsRelativeArrangement = true
        expandedContainer.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)

        let separator = UIView()
        separator.backgroundColor = .separator
        separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        expandedContainer.addArrangedSubview(separator)

        expandedContainer.setCustomSpacing(10, after: separator)

        let yourAnswerTitle = UILabel()
        yourAnswerTitle.text = "Your Answer"
        yourAnswerTitle.font = .preferredFont(forTextStyle: .caption1)
        yourAnswerTitle.textColor = .secondaryLabel
        expandedContainer.addArrangedSubview(yourAnswerTitle)

        userAnswerLabel.font = .preferredFont(forTextStyle: .body)
        userAnswerLabel.textColor = .label
        userAnswerLabel.numberOfLines = 0
        expandedContainer.addArrangedSubview(userAnswerLabel)

        expandedContainer.setCustomSpacing(12, after: userAnswerLabel)

        let feedbackTitle = UILabel()
        feedbackTitle.text = "Feedback"
        feedbackTitle.font = .preferredFont(forTextStyle: .caption1)
        feedbackTitle.textColor = .secondaryLabel
        expandedContainer.addArrangedSubview(feedbackTitle)

        feedbackLabel.font = .preferredFont(forTextStyle: .body)
        feedbackLabel.textColor = .label
        feedbackLabel.numberOfLines = 0
        expandedContainer.addArrangedSubview(feedbackLabel)

        expandedContainer.setCustomSpacing(12, after: feedbackLabel)

        let bulletTitle = UILabel()
        bulletTitle.text = "Key Points"
        bulletTitle.font = .preferredFont(forTextStyle: .caption1)
        bulletTitle.textColor = .secondaryLabel
        expandedContainer.addArrangedSubview(bulletTitle)

        bulletPointsStack.axis = .vertical
        bulletPointsStack.spacing = 4
        expandedContainer.addArrangedSubview(bulletPointsStack)

        // Background context section
        backgroundContextContainer.axis = .vertical
        backgroundContextContainer.spacing = 4
        backgroundContextContainer.isHidden = true

        let bgTitle = UILabel()
        bgTitle.text = "Additional Context"
        bgTitle.font = .preferredFont(forTextStyle: .caption1)
        bgTitle.textColor = .secondaryLabel
        backgroundContextContainer.addArrangedSubview(bgTitle)

        backgroundContextStack.axis = .vertical
        backgroundContextStack.spacing = 2
        backgroundContextContainer.addArrangedSubview(backgroundContextStack)

        expandedContainer.setCustomSpacing(12, after: bulletPointsStack)
        expandedContainer.addArrangedSubview(backgroundContextContainer)

        // Source refs section
        sourceRefsContainer.axis = .vertical
        sourceRefsContainer.spacing = 4
        sourceRefsContainer.isHidden = true

        let srcTitle = UILabel()
        srcTitle.text = "Review in Your Notes"
        srcTitle.font = .preferredFont(forTextStyle: .caption1)
        srcTitle.textColor = .secondaryLabel
        sourceRefsContainer.addArrangedSubview(srcTitle)

        sourceRefsLabel.font = .preferredFont(forTextStyle: .callout)
        sourceRefsLabel.textColor = .secondaryLabel
        sourceRefsLabel.numberOfLines = 0
        sourceRefsContainer.addArrangedSubview(sourceRefsLabel)

        expandedContainer.setCustomSpacing(12, after: backgroundContextContainer)
        expandedContainer.addArrangedSubview(sourceRefsContainer)

        outerStack.addArrangedSubview(expandedContainer)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            outerStack.topAnchor.constraint(equalTo: cardView.topAnchor),
            outerStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            outerStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            outerStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            gradeBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 36),
            gradeBadge.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func configure(question: String, grade: Int16, userAnswer: String, feedback: String, bulletPoints: [String], bulletPointsHit: [Bool], sourceRefs: [String], backgroundContext: [String], needsVerification: Bool) {
        questionLabel.text = question

        gradeBadge.text = " \(grade)/5 "
        let gradeColor: UIColor
        switch grade {
        case 4...5: gradeColor = .systemGreen
        case 3: gradeColor = .systemYellow
        case 2: gradeColor = .systemOrange
        default: gradeColor = .systemRed
        }
        gradeBadge.backgroundColor = gradeColor.withAlphaComponent(0.2)
        gradeBadge.textColor = gradeColor

        verificationBadge.isHidden = !needsVerification

        userAnswerLabel.text = userAnswer
        feedbackLabel.text = feedback

        bulletPointsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, point) in bulletPoints.enumerated() {
            let label = UILabel()
            let hit = index < bulletPointsHit.count ? bulletPointsHit[index] : false
            let icon = hit ? "checkmark.circle.fill" : "xmark.circle"
            let color: UIColor = hit ? .systemGreen : .systemRed
            let attachment = NSTextAttachment()
            attachment.image = UIImage(systemName: icon)?.withTintColor(color, renderingMode: .alwaysOriginal)
            let attrStr = NSMutableAttributedString(attachment: attachment)
            attrStr.append(NSAttributedString(string: " \(point)"))
            label.attributedText = attrStr
            label.font = .preferredFont(forTextStyle: .callout)
            label.numberOfLines = 0
            bulletPointsStack.addArrangedSubview(label)
        }

        // Background context
        backgroundContextStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if !backgroundContext.isEmpty {
            backgroundContextContainer.isHidden = false
            for ctx in backgroundContext {
                let label = UILabel()
                label.text = ctx
                label.font = .preferredFont(forTextStyle: .callout)
                label.textColor = .secondaryLabel
                label.numberOfLines = 0
                backgroundContextStack.addArrangedSubview(label)
            }
        } else {
            backgroundContextContainer.isHidden = true
        }

        // Source refs
        if !sourceRefs.isEmpty {
            sourceRefsContainer.isHidden = false
            sourceRefsLabel.text = sourceRefs.joined(separator: ", ")
        } else {
            sourceRefsContainer.isHidden = true
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isExpanded = false
        expandedContainer.isHidden = true
        verificationBadge.isHidden = true
        backgroundContextContainer.isHidden = true
        sourceRefsContainer.isHidden = true
    }

    func toggleExpanded() {
        isExpanded.toggle()
        expandedContainer.isHidden = !isExpanded
    }

    func setExpanded(_ expanded: Bool) {
        isExpanded = expanded
        expandedContainer.isHidden = !expanded
    }
}
