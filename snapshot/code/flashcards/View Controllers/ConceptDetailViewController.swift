import UIKit

class ConceptDetailViewController: UIViewController {

    var concept: Concept?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = concept?.name ?? "Concept"
        view.backgroundColor = .systemBackground
        setupUI()
        populateContent()
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func populateContent() {
        guard let concept = concept else { return }

        // Title
        let titleLabel = UILabel()
        titleLabel.text = concept.name
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(titleLabel)

        // Tier badge
        let tierLabel = UILabel()
        tierLabel.text = tierDisplayText(for: concept.tier)
        tierLabel.font = .preferredFont(forTextStyle: .subheadline)
        tierLabel.textColor = .secondaryLabel
        contentStack.addArrangedSubview(tierLabel)

        // Overview (main content)
        if let overview = concept.overview, !overview.isEmpty {
            let overviewLabel = UILabel()
            overviewLabel.text = overview
            overviewLabel.font = .preferredFont(forTextStyle: .body)
            overviewLabel.numberOfLines = 0
            contentStack.addArrangedSubview(overviewLabel)
        } else {
            let noOverviewLabel = UILabel()
            noOverviewLabel.text = "No detailed overview available for this concept."
            noOverviewLabel.font = .preferredFont(forTextStyle: .body)
            noOverviewLabel.textColor = .tertiaryLabel
            noOverviewLabel.numberOfLines = 0
            contentStack.addArrangedSubview(noOverviewLabel)
        }

        // Separator
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        contentStack.addArrangedSubview(separator)

        // Summary section
        if let summary = concept.summary, !summary.isEmpty {
            let summaryHeader = makeSectionHeader("Summary")
            contentStack.addArrangedSubview(summaryHeader)

            let summaryLabel = UILabel()
            summaryLabel.text = summary
            summaryLabel.font = .preferredFont(forTextStyle: .body)
            summaryLabel.numberOfLines = 0
            contentStack.addArrangedSubview(summaryLabel)
        }

        // Why It Matters section
        if let rationale = concept.importanceRationale, !rationale.isEmpty {
            let rationaleHeader = makeSectionHeader("Why It Matters")
            contentStack.addArrangedSubview(rationaleHeader)

            let rationaleLabel = UILabel()
            rationaleLabel.text = rationale
            rationaleLabel.font = .preferredFont(forTextStyle: .body)
            rationaleLabel.numberOfLines = 0
            contentStack.addArrangedSubview(rationaleLabel)
        }
    }

    private func makeSectionHeader(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        return label
    }

    private func tierDisplayText(for tier: Int16) -> String {
        switch tier {
        case 1: return "Tier 1 — Foundation"
        case 2: return "Tier 2 — Connection"
        case 3: return "Tier 3 — Synthesis"
        default: return "Tier \(tier)"
        }
    }
}
