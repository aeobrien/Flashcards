import UIKit

class ConceptReviewViewController: UIViewController {

    // MARK: - Properties

    var deckName: String = ""
    var sourceDescription: String = ""
    var originalNotes: String = ""
    var enrichedConcepts: [EnrichedConcept] = []
    var extractionReport: ExtractionReport?

    private let aiService = AICardGenerationService()
    private let loadingOverlay = LoadingOverlayView()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let generateButton = GradientButton(frame: .zero)
    private let deckTitleField = UITextField()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Review Concepts"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addConceptTapped))

        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        // Header with deck title, source description, and report summary
        let headerStack = UIStackView()
        headerStack.axis = .vertical
        headerStack.spacing = 8
        headerStack.isLayoutMarginsRelativeArrangement = true
        headerStack.layoutMargins = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)

        deckTitleField.text = deckName
        deckTitleField.font = .systemFont(ofSize: 18, weight: .bold)
        deckTitleField.borderStyle = .none
        deckTitleField.placeholder = "Deck title"
        deckTitleField.addTarget(self, action: #selector(deckTitleChanged), for: .editingChanged)
        headerStack.addArrangedSubview(deckTitleField)

        if !sourceDescription.isEmpty {
            let descLabel = UILabel()
            descLabel.text = sourceDescription
            descLabel.font = .preferredFont(forTextStyle: .caption1)
            descLabel.textColor = .secondaryLabel
            descLabel.numberOfLines = 0
            headerStack.addArrangedSubview(descLabel)
        }

        if let report = extractionReport {
            let reportLabel = UILabel()
            var reportText = "\(report.conceptCount) concepts identified"
            if let tb = report.tierBreakdown {
                reportText += ": \(tb.tier1 ?? 0) T1, \(tb.tier2 ?? 0) T2, \(tb.tier3 ?? 0) T3"
            }
            if report.verificationFlags > 0 {
                reportText += ", \(report.verificationFlags) flagged for verification"
            }
            reportLabel.text = reportText
            reportLabel.font = .preferredFont(forTextStyle: .caption2)
            reportLabel.textColor = .tertiaryLabel
            headerStack.addArrangedSubview(reportLabel)
        }

        let separator = UIView()
        separator.backgroundColor = .separator
        separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        headerStack.addArrangedSubview(separator)

        let headerContainer = UIView()
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(headerStack)
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            headerStack.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            headerStack.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            headerStack.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor)
        ])

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ConceptTableViewCell.self, forCellReuseIdentifier: "ConceptCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120

        // Set header
        tableView.tableHeaderView = headerContainer
        headerContainer.setNeedsLayout()
        headerContainer.layoutIfNeeded()
        let size = headerContainer.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        headerContainer.frame.size = size
        tableView.tableHeaderView = headerContainer

        view.addSubview(tableView)

        generateButton.translatesAutoresizingMaskIntoConstraints = false
        generateButton.setTitle("Generate Cards", for: .normal)
        generateButton.setTitleColor(.white, for: .normal)
        generateButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        generateButton.startColor = UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0)
        generateButton.endColor = UIColor(red: 0.4, green: 0.3, blue: 0.9, alpha: 1.0)
        generateButton.cornerRadius = 14
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
        view.addSubview(generateButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: generateButton.topAnchor, constant: -12),

            generateButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            generateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            generateButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            generateButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Actions

    @objc private func deckTitleChanged() {
        deckName = deckTitleField.text ?? ""
    }

    @objc private func addConceptTapped() {
        let alert = UIAlertController(title: "Add Concept", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Concept name" }
        alert.addTextField { tf in tf.placeholder = "Summary (optional)" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            let summary = alert.textFields?[1].text ?? ""
            let newConcept = EnrichedConcept(
                conceptId: "user_\(UUID().uuidString.prefix(8))",
                title: name,
                summary: summary,
                importanceRationale: "User-added concept",
                relatedConcepts: [],
                relationshipNotes: "",
                needsVerification: false,
                verificationNote: nil,
                contextNote: nil,
                sourceRefs: [],
                userMentioned: nil,
                userGapNote: nil,
                tier: 1,
                dependsOn: [],
                overview: ""
            )
            self?.enrichedConcepts.append(newConcept)
            self?.tableView.reloadData()
        })
        present(alert, animated: true)
    }

    @objc private func generateTapped() {
        let selectedConcepts = enrichedConcepts.filter { $0.isIncluded }

        guard !selectedConcepts.isEmpty else {
            Alert.showAlert(on: self, title: "No Concepts", message: "Please include at least one concept.")
            return
        }

        let conceptCount = selectedConcepts.count
        loadingOverlay.show(in: view, message: "Generating flashcards for \(conceptCount) concepts...")

        Task {
            var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
            backgroundTaskID = UIApplication.shared.beginBackgroundTask {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }

            defer {
                if backgroundTaskID != .invalid {
                    UIApplication.shared.endBackgroundTask(backgroundTaskID)
                }
            }

            do {
                let cards = try await aiService.generateCards(for: selectedConcepts, originalNotes: originalNotes) { [weak self] status in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        if status.hasPrefix("[detail]") {
                            let detail = String(status.dropFirst("[detail]".count))
                            self.loadingOverlay.updateDetail(detail)
                        } else if status.hasPrefix("[progress]") {
                            let valueStr = String(status.dropFirst("[progress]".count))
                            if let fraction = Float(valueStr) {
                                self.loadingOverlay.updateProgress(fraction)
                            }
                        } else {
                            self.loadingOverlay.updateMessage(status)
                        }
                    }
                }

                await MainActor.run {
                    loadingOverlay.dismiss()
                    let cardReviewVC = CardReviewViewController()
                    cardReviewVC.deckName = deckName
                    cardReviewVC.sourceDescription = sourceDescription
                    cardReviewVC.originalNotes = originalNotes
                    cardReviewVC.enrichedConcepts = selectedConcepts
                    cardReviewVC.generatedCards = cards
                    navigationController?.pushViewController(cardReviewVC, animated: true)
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

// MARK: - UITableViewDelegate & DataSource

extension ConceptReviewViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return enrichedConcepts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConceptCell", for: indexPath) as! ConceptTableViewCell
        let concept = enrichedConcepts[indexPath.row]
        cell.configure(with: concept)
        cell.delegate = self
        cell.tag = indexPath.row
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            enrichedConcepts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}

// MARK: - ConceptTableViewCellDelegate

extension ConceptReviewViewController: ConceptTableViewCellDelegate {

    func conceptCell(_ cell: ConceptTableViewCell, didToggleInclude isIncluded: Bool) {
        let index = cell.tag
        guard index < enrichedConcepts.count else { return }
        enrichedConcepts[index].isIncluded = isIncluded
    }

    func conceptCell(_ cell: ConceptTableViewCell, didUpdateName name: String) {
        let index = cell.tag
        guard index < enrichedConcepts.count else { return }
        enrichedConcepts[index].title = name
    }
}
