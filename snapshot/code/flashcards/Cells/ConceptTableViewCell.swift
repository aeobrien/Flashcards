import UIKit

protocol ConceptTableViewCellDelegate: AnyObject {
    func conceptCell(_ cell: ConceptTableViewCell, didToggleInclude isIncluded: Bool)
    func conceptCell(_ cell: ConceptTableViewCell, didUpdateName name: String)
}

class ConceptTableViewCell: UITableViewCell {

    weak var delegate: ConceptTableViewCellDelegate?

    private let nameTextField = UITextField()
    private let tierBadge = UILabel()
    private let includeSwitch = UISwitch()
    private let summaryLabel = UILabel()
    private let importanceLabel = UILabel()
    private let importanceToggle = UIButton(type: .system)
    private let verificationBadge = UIImageView()
    private let sourceRefsLabel = UILabel()
    private let userMentionedIcon = UIImageView()
    private let gapNoteLabel = UILabel()
    private let contextNoteLabel = UILabel()
    private var importanceExpanded = false

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
        importanceExpanded = false
        importanceLabel.isHidden = true
        importanceToggle.setTitle("Why important?", for: .normal)
        verificationBadge.isHidden = true
        sourceRefsLabel.isHidden = true
        userMentionedIcon.isHidden = true
        gapNoteLabel.isHidden = true
        contextNoteLabel.isHidden = true
        tierBadge.isHidden = true
    }

    private func setupViews() {
        selectionStyle = .none

        nameTextField.font = .systemFont(ofSize: 16, weight: .medium)
        nameTextField.borderStyle = .none
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.addTarget(self, action: #selector(nameChanged), for: .editingDidEnd)
        contentView.addSubview(nameTextField)

        tierBadge.font = .systemFont(ofSize: 10, weight: .bold)
        tierBadge.textAlignment = .center
        tierBadge.layer.cornerRadius = 4
        tierBadge.layer.masksToBounds = true
        tierBadge.translatesAutoresizingMaskIntoConstraints = false
        tierBadge.isHidden = true
        contentView.addSubview(tierBadge)

        includeSwitch.translatesAutoresizingMaskIntoConstraints = false
        includeSwitch.isOn = true
        includeSwitch.addTarget(self, action: #selector(switchToggled), for: .valueChanged)
        contentView.addSubview(includeSwitch)

        // User mentioned icon (green check, red X, or orange ~)
        userMentionedIcon.translatesAutoresizingMaskIntoConstraints = false
        userMentionedIcon.contentMode = .scaleAspectFit
        userMentionedIcon.isHidden = true
        contentView.addSubview(userMentionedIcon)

        // Verification badge
        verificationBadge.translatesAutoresizingMaskIntoConstraints = false
        verificationBadge.image = UIImage(systemName: "exclamationmark.triangle.fill")
        verificationBadge.tintColor = .systemOrange
        verificationBadge.contentMode = .scaleAspectFit
        verificationBadge.isHidden = true
        contentView.addSubview(verificationBadge)

        summaryLabel.font = .preferredFont(forTextStyle: .caption1)
        summaryLabel.textColor = .secondaryLabel
        summaryLabel.numberOfLines = 0
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(summaryLabel)

        // Context note (distinct style)
        contextNoteLabel.font = .preferredFont(forTextStyle: .caption1)
        contextNoteLabel.textColor = .systemTeal
        contextNoteLabel.numberOfLines = 0
        contextNoteLabel.translatesAutoresizingMaskIntoConstraints = false
        contextNoteLabel.isHidden = true
        contentView.addSubview(contextNoteLabel)

        // Importance rationale (expandable)
        importanceToggle.translatesAutoresizingMaskIntoConstraints = false
        importanceToggle.setTitle("Why important?", for: .normal)
        importanceToggle.titleLabel?.font = .preferredFont(forTextStyle: .caption2)
        importanceToggle.setTitleColor(.systemBlue, for: .normal)
        importanceToggle.contentHorizontalAlignment = .leading
        importanceToggle.addTarget(self, action: #selector(toggleImportance), for: .touchUpInside)
        contentView.addSubview(importanceToggle)

        importanceLabel.font = .preferredFont(forTextStyle: .caption2)
        importanceLabel.textColor = .tertiaryLabel
        importanceLabel.numberOfLines = 0
        importanceLabel.isHidden = true
        importanceLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(importanceLabel)

        // Gap note
        gapNoteLabel.font = .preferredFont(forTextStyle: .caption2)
        gapNoteLabel.textColor = .systemOrange
        gapNoteLabel.numberOfLines = 0
        gapNoteLabel.isHidden = true
        gapNoteLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(gapNoteLabel)

        // Source refs
        sourceRefsLabel.font = .preferredFont(forTextStyle: .caption2)
        sourceRefsLabel.textColor = .tertiaryLabel
        sourceRefsLabel.numberOfLines = 0
        sourceRefsLabel.isHidden = true
        sourceRefsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sourceRefsLabel)

        let trailingGuide = includeSwitch.leadingAnchor

        NSLayoutConstraint.activate([
            includeSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            includeSwitch.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),

            userMentionedIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            userMentionedIcon.centerYAnchor.constraint(equalTo: nameTextField.centerYAnchor),
            userMentionedIcon.widthAnchor.constraint(equalToConstant: 18),
            userMentionedIcon.heightAnchor.constraint(equalToConstant: 18),

            verificationBadge.leadingAnchor.constraint(equalTo: userMentionedIcon.trailingAnchor, constant: 4),
            verificationBadge.centerYAnchor.constraint(equalTo: nameTextField.centerYAnchor),
            verificationBadge.widthAnchor.constraint(equalToConstant: 16),
            verificationBadge.heightAnchor.constraint(equalToConstant: 16),

            nameTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: tierBadge.leadingAnchor, constant: -6),

            tierBadge.centerYAnchor.constraint(equalTo: nameTextField.centerYAnchor),
            tierBadge.trailingAnchor.constraint(equalTo: trailingGuide, constant: -12),
            tierBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 24),
            tierBadge.heightAnchor.constraint(equalToConstant: 18),

            summaryLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 4),
            summaryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            summaryLabel.trailingAnchor.constraint(equalTo: trailingGuide, constant: -12),

            contextNoteLabel.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 4),
            contextNoteLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contextNoteLabel.trailingAnchor.constraint(equalTo: trailingGuide, constant: -12),

            importanceToggle.topAnchor.constraint(equalTo: contextNoteLabel.bottomAnchor, constant: 4),
            importanceToggle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            importanceLabel.topAnchor.constraint(equalTo: importanceToggle.bottomAnchor, constant: 2),
            importanceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            importanceLabel.trailingAnchor.constraint(equalTo: trailingGuide, constant: -12),

            gapNoteLabel.topAnchor.constraint(equalTo: importanceLabel.bottomAnchor, constant: 4),
            gapNoteLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            gapNoteLabel.trailingAnchor.constraint(equalTo: trailingGuide, constant: -12),

            sourceRefsLabel.topAnchor.constraint(equalTo: gapNoteLabel.bottomAnchor, constant: 4),
            sourceRefsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sourceRefsLabel.trailingAnchor.constraint(equalTo: trailingGuide, constant: -12),
            sourceRefsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    func configure(with concept: EnrichedConcept) {
        nameTextField.text = concept.title
        summaryLabel.text = concept.summary
        includeSwitch.isOn = concept.isIncluded
        contentView.alpha = concept.isIncluded ? 1.0 : 0.5

        // Tier badge
        tierBadge.text = " T\(concept.tier) "
        tierBadge.isHidden = false
        switch concept.tier {
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

        importanceLabel.text = concept.importanceRationale

        // Verification badge
        verificationBadge.isHidden = !concept.needsVerification

        // Context note
        if let note = concept.contextNote, !note.isEmpty {
            contextNoteLabel.text = "Context: \(note)"
            contextNoteLabel.isHidden = false
        } else {
            contextNoteLabel.isHidden = true
        }

        // User mentioned status
        if let mentioned = concept.userMentioned {
            userMentionedIcon.isHidden = false
            switch mentioned {
            case "true":
                userMentionedIcon.image = UIImage(systemName: "checkmark.circle.fill")
                userMentionedIcon.tintColor = .systemGreen
            case "false":
                userMentionedIcon.image = UIImage(systemName: "xmark.circle.fill")
                userMentionedIcon.tintColor = .systemRed
            case "partial":
                userMentionedIcon.image = UIImage(systemName: "minus.circle.fill")
                userMentionedIcon.tintColor = .systemOrange
            default:
                userMentionedIcon.isHidden = true
            }
        } else {
            userMentionedIcon.isHidden = true
        }

        // Gap note
        if let gap = concept.userGapNote, !gap.isEmpty {
            gapNoteLabel.text = "Gap: \(gap)"
            gapNoteLabel.isHidden = false
        } else {
            gapNoteLabel.isHidden = true
        }

        // Source refs
        if !concept.sourceRefs.isEmpty {
            sourceRefsLabel.text = concept.sourceRefs.joined(separator: " | ")
            sourceRefsLabel.isHidden = false
        } else {
            sourceRefsLabel.isHidden = true
        }
    }

    @objc private func toggleImportance() {
        importanceExpanded.toggle()
        importanceLabel.isHidden = !importanceExpanded
        importanceToggle.setTitle(importanceExpanded ? "Hide" : "Why important?", for: .normal)

        // Trigger table view layout update
        if let tableView = superview as? UITableView {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }

    @objc private func switchToggled() {
        contentView.alpha = includeSwitch.isOn ? 1.0 : 0.5
        delegate?.conceptCell(self, didToggleInclude: includeSwitch.isOn)
    }

    @objc private func nameChanged() {
        delegate?.conceptCell(self, didUpdateName: nameTextField.text ?? "")
    }
}
