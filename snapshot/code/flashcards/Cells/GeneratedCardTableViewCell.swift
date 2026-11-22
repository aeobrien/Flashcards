import UIKit

class GeneratedCardTableViewCell: UITableViewCell {

    private let questionLabel = UILabel()
    private let conceptBadge = UILabel()
    private let cardTypeBadge = UILabel()
    private let tierBadge = UILabel()
    private let constraintsLabel = UILabel()
    private let bulletPreview = UILabel()
    private let checkboxButton = UIButton(type: .system)

    var isChecked: Bool = true {
        didSet {
            updateCheckbox()
        }
    }

    var onCheckboxToggle: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        constraintsLabel.isHidden = true
        cardTypeBadge.isHidden = true
        tierBadge.isHidden = true
    }

    private func setupViews() {
        selectionStyle = .none

        checkboxButton.translatesAutoresizingMaskIntoConstraints = false
        checkboxButton.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
        contentView.addSubview(checkboxButton)

        conceptBadge.font = .systemFont(ofSize: 11, weight: .medium)
        conceptBadge.textColor = .systemBlue
        conceptBadge.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        conceptBadge.layer.cornerRadius = 4
        conceptBadge.layer.masksToBounds = true
        conceptBadge.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(conceptBadge)

        cardTypeBadge.font = .systemFont(ofSize: 10, weight: .semibold)
        cardTypeBadge.layer.cornerRadius = 4
        cardTypeBadge.layer.masksToBounds = true
        cardTypeBadge.translatesAutoresizingMaskIntoConstraints = false
        cardTypeBadge.isHidden = true
        contentView.addSubview(cardTypeBadge)

        tierBadge.font = .systemFont(ofSize: 10, weight: .bold)
        tierBadge.layer.cornerRadius = 4
        tierBadge.layer.masksToBounds = true
        tierBadge.translatesAutoresizingMaskIntoConstraints = false
        tierBadge.isHidden = true
        contentView.addSubview(tierBadge)

        questionLabel.font = .systemFont(ofSize: 15, weight: .medium)
        questionLabel.textColor = .label
        questionLabel.numberOfLines = 0
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(questionLabel)

        constraintsLabel.font = .italicSystemFont(ofSize: 12)
        constraintsLabel.textColor = .tertiaryLabel
        constraintsLabel.numberOfLines = 0
        constraintsLabel.isHidden = true
        constraintsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(constraintsLabel)

        bulletPreview.font = .preferredFont(forTextStyle: .caption1)
        bulletPreview.textColor = .secondaryLabel
        bulletPreview.numberOfLines = 0
        bulletPreview.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bulletPreview)

        let contentLeading = checkboxButton.trailingAnchor

        NSLayoutConstraint.activate([
            checkboxButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            checkboxButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            checkboxButton.widthAnchor.constraint(equalToConstant: 30),
            checkboxButton.heightAnchor.constraint(equalToConstant: 30),

            conceptBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            conceptBadge.leadingAnchor.constraint(equalTo: contentLeading, constant: 12),

            cardTypeBadge.centerYAnchor.constraint(equalTo: conceptBadge.centerYAnchor),
            cardTypeBadge.leadingAnchor.constraint(equalTo: conceptBadge.trailingAnchor, constant: 6),

            tierBadge.centerYAnchor.constraint(equalTo: conceptBadge.centerYAnchor),
            tierBadge.leadingAnchor.constraint(equalTo: cardTypeBadge.trailingAnchor, constant: 6),

            questionLabel.topAnchor.constraint(equalTo: conceptBadge.bottomAnchor, constant: 4),
            questionLabel.leadingAnchor.constraint(equalTo: contentLeading, constant: 12),
            questionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            constraintsLabel.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 2),
            constraintsLabel.leadingAnchor.constraint(equalTo: contentLeading, constant: 12),
            constraintsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            bulletPreview.topAnchor.constraint(equalTo: constraintsLabel.bottomAnchor, constant: 4),
            bulletPreview.leadingAnchor.constraint(equalTo: contentLeading, constant: 12),
            bulletPreview.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bulletPreview.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])

        updateCheckbox()
    }

    func configure(question: String, conceptName: String, cardType: String?, constraints: [String], bulletPoints: [String], isSelected: Bool, tier: Int = 1) {
        questionLabel.text = question
        conceptBadge.text = " \(conceptName) "
        bulletPreview.text = bulletPoints.map { "- \($0)" }.joined(separator: "\n")
        isChecked = isSelected

        // Tier badge
        tierBadge.text = " T\(tier) "
        tierBadge.isHidden = false
        switch tier {
        case 1:
            tierBadge.textColor = .systemGreen
            tierBadge.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        case 2:
            tierBadge.textColor = .systemOrange
            tierBadge.backgroundColor = .systemOrange.withAlphaComponent(0.1)
        case 3:
            tierBadge.textColor = .systemRed
            tierBadge.backgroundColor = .systemRed.withAlphaComponent(0.1)
        default:
            tierBadge.textColor = .systemGray
            tierBadge.backgroundColor = .systemGray.withAlphaComponent(0.1)
        }

        // Card type badge
        if let type = cardType {
            cardTypeBadge.isHidden = false
            let displayName: String
            let badgeColor: UIColor
            switch type {
            case "explain_in_own_words":
                displayName = "Explain"
                badgeColor = .systemGreen
            case "compare_contrast":
                displayName = "Compare"
                badgeColor = .systemPurple
            case "scenario_application":
                displayName = "Scenario"
                badgeColor = .systemIndigo
            case "metaphor":
                displayName = "Metaphor"
                badgeColor = .systemTeal
            case "counterexample":
                displayName = "Counter"
                badgeColor = .systemRed
            case "define_and_identify":
                displayName = "Define"
                badgeColor = .systemBlue
            case "identify_or_distinguish":
                displayName = "Distinguish"
                badgeColor = .systemCyan
            case "explain_relationship":
                displayName = "Relate"
                badgeColor = .systemMint
            default:
                displayName = type
                badgeColor = .systemGray
            }
            cardTypeBadge.text = " \(displayName) "
            cardTypeBadge.textColor = badgeColor
            cardTypeBadge.backgroundColor = badgeColor.withAlphaComponent(0.1)
        } else {
            cardTypeBadge.isHidden = true
        }

        // Constraints
        if !constraints.isEmpty {
            constraintsLabel.text = constraints.map { "- \($0)" }.joined(separator: "\n")
            constraintsLabel.isHidden = false
        } else {
            constraintsLabel.isHidden = true
        }
    }

    @objc private func checkboxTapped() {
        isChecked.toggle()
        onCheckboxToggle?(isChecked)
    }

    private func updateCheckbox() {
        let imageName = isChecked ? "checkmark.circle.fill" : "circle"
        let color: UIColor = isChecked ? .systemBlue : .systemGray3
        checkboxButton.setImage(UIImage(systemName: imageName), for: .normal)
        checkboxButton.tintColor = color
        contentView.alpha = isChecked ? 1.0 : 0.5
    }
}
