import UIKit

class SessionResultsViewController: UIViewController {

    // MARK: - Properties

    var studySession: StudySession!
    var userAnswers: [(flashcard: Flashcard, answer: String)] = []
    var gradingResults: [GradingResponse] = []
    var confidenceValues: [Int16] = []
    var isGroupSession: Bool = false

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var expandedCells: Set<Int> = []

    private var needsAttentionIndices: [Int] {
        return gradingResults.enumerated().compactMap { index, result in
            result.grade < 3 ? index : nil
        }
    }

    private var wellDoneIndices: [Int] {
        return gradingResults.enumerated().compactMap { index, result in
            result.grade >= 3 ? index : nil
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Session Complete"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
        setupTableView()
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ResultCardTableViewCell.self, forCellReuseIdentifier: "ResultCardCell")
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .systemGroupedBackground
        view.addSubview(tableView)

        // Build summary as the table header
        let header = buildSummaryHeader()
        tableView.tableHeaderView = header
        header.setNeedsLayout()
        header.layoutIfNeeded()
        let size = header.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        header.frame.size = size
        tableView.tableHeaderView = header

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func buildSummaryHeader() -> UIView {
        let wrapper = UIView()

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(stack)

        // Summary card
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous

        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 12
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cardStack)

        let avgGrade = gradingResults.isEmpty ? 0 : Double(gradingResults.reduce(0) { $0 + $1.grade }) / Double(gradingResults.count)

        let progressView = CircularProgressView(frame: .zero)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progress = CGFloat(avgGrade / 5.0)
        progressView.progressColor = CircularProgressView.colorForGrade(avgGrade)
        progressView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        progressView.widthAnchor.constraint(equalToConstant: 100).isActive = true

        let progressContainer = UIView()
        progressContainer.addSubview(progressView)
        progressView.centerXAnchor.constraint(equalTo: progressContainer.centerXAnchor).isActive = true
        progressView.topAnchor.constraint(equalTo: progressContainer.topAnchor).isActive = true
        progressView.bottomAnchor.constraint(equalTo: progressContainer.bottomAnchor).isActive = true
        cardStack.addArrangedSubview(progressContainer)

        let avgLabel = UILabel()
        avgLabel.text = String(format: "Average Grade: %.1f / 5", avgGrade)
        avgLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        avgLabel.textColor = .label
        avgLabel.textAlignment = .center
        cardStack.addArrangedSubview(avgLabel)

        // Early practice indicator
        if studySession.isEarlyPractice {
            let earlyLabel = UILabel()
            earlyLabel.text = "Early practice — scheduling not affected"
            earlyLabel.font = .preferredFont(forTextStyle: .caption1)
            earlyLabel.textColor = .systemOrange
            earlyLabel.textAlignment = .center
            cardStack.addArrangedSubview(earlyLabel)
        }

        let statsStack = UIStackView()
        statsStack.axis = .horizontal
        statsStack.distribution = .equalSpacing
        statsStack.spacing = 12

        statsStack.addArrangedSubview(createStatLabel(value: "\(gradingResults.count)", title: "Reviewed"))
        statsStack.addArrangedSubview(createStatLabel(value: "\(needsAttentionIndices.count)", title: "Need Work"))
        statsStack.addArrangedSubview(createStatLabel(value: "\(gradingResults.filter { $0.grade >= 4 }.count)", title: "Mastered"))
        cardStack.addArrangedSubview(statsStack)

        // Calibration summary if confidence data exists
        let withConfidence = confidenceValues.filter { $0 > 0 }
        if !withConfidence.isEmpty {
            var miscalibrated = 0
            for (i, conf) in confidenceValues.enumerated() where conf > 0 && i < gradingResults.count {
                let grade = gradingResults[i].grade
                if (conf == 3 && grade < 3) || (conf == 1 && grade >= 4) {
                    miscalibrated += 1
                }
            }
            if miscalibrated > 0 {
                let calLabel = UILabel()
                calLabel.text = "\(miscalibrated) miscalibrated answer\(miscalibrated == 1 ? "" : "s")"
                calLabel.font = .preferredFont(forTextStyle: .caption1)
                calLabel.textColor = .systemRed
                calLabel.textAlignment = .center
                cardStack.addArrangedSubview(calLabel)
            }
        }

        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20)
        ])

        stack.addArrangedSubview(card)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -20)
        ])

        return wrapper
    }

    private func createStatLabel(value: String, title: String) -> UIView {
        let container = UIView()
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 24, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .center
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(valueLabel)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .caption1)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: container.topAnchor),
            valueLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 2),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // MARK: - Helpers

    /// Returns the indices for a given section: 0 = needs attention, 1 = well done
    private func indicesForSection(_ section: Int) -> [Int] {
        if !needsAttentionIndices.isEmpty {
            return section == 0 ? needsAttentionIndices : wellDoneIndices
        } else {
            return wellDoneIndices
        }
    }

    // MARK: - Actions

    @objc private func doneTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDelegate & DataSource

extension SessionResultsViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        if gradingResults.isEmpty { return 0 }
        return needsAttentionIndices.isEmpty ? 1 : 2
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if needsAttentionIndices.isEmpty {
            return "Your Results"
        }
        return section == 0 ? "Cards Needing Attention" : "Well Done"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return indicesForSection(section).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCardCell", for: indexPath) as! ResultCardTableViewCell
        let indices = indicesForSection(indexPath.section)
        let originalIndex = indices[indexPath.row]
        let flashcard = userAnswers[originalIndex].flashcard
        let answer = userAnswers[originalIndex].answer
        let gradeResult = gradingResults[originalIndex]

        // Build question text with deck origin for group sessions
        var questionText = flashcard.frontLabel ?? ""
        if isGroupSession, let deckName = flashcard.deck?.deckName {
            questionText = "[\(deckName)] \(questionText)"
        }

        // Calibration flag
        let confidence = originalIndex < confidenceValues.count ? confidenceValues[originalIndex] : 0
        var feedbackText = gradeResult.feedback
        if confidence == 3 && gradeResult.grade < 3 {
            feedbackText = "⚠️ Overconfident — you rated High but scored \(gradeResult.grade)/5\n\n" + feedbackText
        } else if confidence == 1 && gradeResult.grade >= 4 {
            feedbackText = "💡 Underconfident — you rated Low but scored \(gradeResult.grade)/5\n\n" + feedbackText
        }

        cell.configure(
            question: questionText,
            grade: Int16(gradeResult.grade),
            userAnswer: answer,
            feedback: feedbackText,
            bulletPoints: flashcard.bulletPoints,
            bulletPointsHit: gradeResult.bulletPointsHit,
            sourceRefs: flashcard.sourceRefs,
            backgroundContext: flashcard.backgroundContext,
            needsVerification: flashcard.needsVerification
        )

        let cellKey = indexPath.section * 1000 + indexPath.row
        cell.setExpanded(expandedCells.contains(cellKey))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ResultCardTableViewCell else { return }
        let cellKey = indexPath.section * 1000 + indexPath.row
        if expandedCells.contains(cellKey) {
            expandedCells.remove(cellKey)
        } else {
            expandedCells.insert(cellKey)
        }
        cell.toggleExpanded()
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}
