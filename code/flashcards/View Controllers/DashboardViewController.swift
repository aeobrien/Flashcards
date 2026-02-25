import UIKit
import CoreData

class DashboardViewController: UIViewController {

    // MARK: - Properties

    var deck: Deck?
    var group: Group?

    private let schedulingService = SchedulingService(context: AppDelegate.getContext())
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Dashboard"
        view.backgroundColor = .systemGroupedBackground

        setupUI()
        loadData()
    }

    // MARK: - Setup

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    // MARK: - Data

    private func loadData() {
        let allCards: [Flashcard]
        let allResponses: [SessionResponse]

        if let group = group {
            let decks = group.decks?.allObjects as? [Deck] ?? []
            allCards = decks.flatMap { ($0.flashcards?.allObjects as? [Flashcard]) ?? [] }
            let sessions = decks.flatMap { ($0.studySessions?.allObjects as? [StudySession]) ?? [] }
            allResponses = sessions.flatMap { ($0.responses?.allObjects as? [SessionResponse]) ?? [] }
        } else if let deck = deck {
            allCards = (deck.flashcards?.allObjects as? [Flashcard]) ?? []
            let sessions = (deck.studySessions?.allObjects as? [StudySession]) ?? []
            allResponses = sessions.flatMap { ($0.responses?.allObjects as? [SessionResponse]) ?? [] }
        } else {
            return
        }

        addCardStateSection(allCards)
        addTierBreakdownSection(allCards)
        addOverdueSection(allCards)
        addGradeHistorySection(allResponses)
        addCalibrationSection(allResponses)
        addWeakestConceptsSection(allCards, allResponses)
    }

    // MARK: - Sections

    private func addCardStateSection(_ cards: [Flashcard]) {
        let card = createSectionCard(title: "Card States")

        var locked = 0, available = 0, learning = 0, mastered = 0
        for c in cards {
            switch c.effectiveCardState {
            case "locked": locked += 1
            case "available": available += 1
            case "learning": learning += 1
            case "mastered": mastered += 1
            default: available += 1
            }
        }

        let total = max(cards.count, 1)
        let items: [(String, Int, UIColor)] = [
            ("Mastered", mastered, .systemGreen),
            ("Learning", learning, .systemBlue),
            ("Available", available, .systemOrange),
            ("Locked", locked, .systemGray)
        ]

        for (label, count, color) in items {
            let row = createProgressRow(label: label, count: count, total: total, color: color)
            card.addArrangedSubview(row)
        }

        contentStack.addArrangedSubview(card)
    }

    private func addTierBreakdownSection(_ cards: [Flashcard]) {
        let card = createSectionCard(title: "Tier Breakdown")

        var t1 = 0, t2 = 0, t3 = 0
        for c in cards {
            switch c.tier {
            case 1: t1 += 1
            case 2: t2 += 1
            case 3: t3 += 1
            default: t1 += 1
            }
        }

        let total = max(cards.count, 1)
        let items: [(String, Int, UIColor)] = [
            ("Tier 1 (Foundation)", t1, .systemBlue),
            ("Tier 2 (Connection)", t2, .systemPurple),
            ("Tier 3 (Synthesis)", t3, .systemIndigo)
        ]

        for (label, count, color) in items {
            let row = createProgressRow(label: label, count: count, total: total, color: color)
            card.addArrangedSubview(row)
        }

        contentStack.addArrangedSubview(card)
    }

    private func addOverdueSection(_ cards: [Flashcard]) {
        let now = Date()
        let overdue = cards.filter { card in
            let state = card.effectiveCardState
            guard state == "available" || state == "learning" else { return false }
            guard let next = card.nextReviewDate else { return true }
            return next <= now
        }

        let card = createSectionCard(title: "Review Status")

        let label = UILabel()
        label.font = .systemFont(ofSize: 36, weight: .bold)
        label.textAlignment = .center
        label.text = "\(overdue.count)"
        label.textColor = overdue.isEmpty ? .systemGreen : .systemOrange
        card.addArrangedSubview(label)

        let subtitle = UILabel()
        subtitle.text = overdue.isEmpty ? "All caught up!" : "cards due for review"
        subtitle.font = .preferredFont(forTextStyle: .subheadline)
        subtitle.textColor = .secondaryLabel
        subtitle.textAlignment = .center
        card.addArrangedSubview(subtitle)

        contentStack.addArrangedSubview(card)
    }

    private func addGradeHistorySection(_ responses: [SessionResponse]) {
        let card = createSectionCard(title: "Grade History")

        guard !responses.isEmpty else {
            let label = UILabel()
            label.text = "No study sessions yet."
            label.font = .preferredFont(forTextStyle: .body)
            label.textColor = .secondaryLabel
            card.addArrangedSubview(label)
            contentStack.addArrangedSubview(card)
            return
        }

        let sorted = responses.sorted { ($0.answeredAt ?? .distantPast) < ($1.answeredAt ?? .distantPast) }
        let totalGrade = sorted.reduce(0) { $0 + Int($1.grade) }
        let avg = Double(totalGrade) / Double(sorted.count)

        let avgLabel = UILabel()
        avgLabel.text = String(format: "Average Grade: %.1f / 5", avg)
        avgLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        avgLabel.textAlignment = .center
        card.addArrangedSubview(avgLabel)

        let countLabel = UILabel()
        countLabel.text = "\(sorted.count) total responses across \(Set(sorted.compactMap { $0.session?.sessionID }).count) sessions"
        countLabel.font = .preferredFont(forTextStyle: .caption1)
        countLabel.textColor = .secondaryLabel
        countLabel.textAlignment = .center
        card.addArrangedSubview(countLabel)

        // Grade distribution
        var gradeDist: [Int: Int] = [:]
        for r in sorted { gradeDist[Int(r.grade), default: 0] += 1 }

        let total = max(sorted.count, 1)
        for g in 1...5 {
            let count = gradeDist[g] ?? 0
            let color: UIColor = g >= 4 ? .systemGreen : (g >= 3 ? .systemYellow : .systemRed)
            let row = createProgressRow(label: "Grade \(g)", count: count, total: total, color: color)
            card.addArrangedSubview(row)
        }

        contentStack.addArrangedSubview(card)
    }

    private func addCalibrationSection(_ responses: [SessionResponse]) {
        let withConfidence = responses.filter { $0.confidence > 0 }
        guard !withConfidence.isEmpty else { return }

        let card = createSectionCard(title: "Calibration")

        var overconfident = 0
        var underconfident = 0
        var calibrated = 0

        for r in withConfidence {
            let conf = r.confidence // 1=Low, 2=Med, 3=High
            let grade = r.grade

            if conf == 3 && grade < 3 {
                overconfident += 1
            } else if conf == 1 && grade >= 4 {
                underconfident += 1
            } else {
                calibrated += 1
            }
        }

        let total = withConfidence.count
        let items: [(String, Int, UIColor)] = [
            ("Well Calibrated", calibrated, .systemGreen),
            ("Overconfident", overconfident, .systemRed),
            ("Underconfident", underconfident, .systemBlue)
        ]

        for (label, count, color) in items {
            let row = createProgressRow(label: label, count: count, total: total, color: color)
            card.addArrangedSubview(row)
        }

        contentStack.addArrangedSubview(card)
    }

    private func addWeakestConceptsSection(_ cards: [Flashcard], _ responses: [SessionResponse]) {
        guard !responses.isEmpty else { return }

        // Group responses by concept
        var conceptGrades: [String: [Int16]] = [:]
        for r in responses {
            guard let conceptName = r.flashcard?.concept?.name, !conceptName.isEmpty else { continue }
            conceptGrades[conceptName, default: []].append(r.grade)
        }

        let weakest = conceptGrades
            .map { (name: $0.key, avg: Double($0.value.reduce(0, +)) / Double($0.value.count), count: $0.value.count) }
            .filter { $0.count >= 2 }
            .sorted { $0.avg < $1.avg }
            .prefix(5)

        guard !weakest.isEmpty else { return }

        let card = createSectionCard(title: "Weakest Concepts")

        for concept in weakest {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8

            let nameLabel = UILabel()
            nameLabel.text = concept.name
            nameLabel.font = .preferredFont(forTextStyle: .body)
            nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            row.addArrangedSubview(nameLabel)

            let gradeLabel = UILabel()
            gradeLabel.text = String(format: "%.1f avg", concept.avg)
            gradeLabel.font = .preferredFont(forTextStyle: .caption1)
            gradeLabel.textColor = concept.avg < 3 ? .systemRed : .systemOrange
            gradeLabel.setContentHuggingPriority(.required, for: .horizontal)
            row.addArrangedSubview(gradeLabel)

            card.addArrangedSubview(row)
        }

        contentStack.addArrangedSubview(card)
    }

    // MARK: - Helpers

    private func createSectionCard(title: String) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        let bg = UIView()
        bg.backgroundColor = .secondarySystemGroupedBackground
        bg.layer.cornerRadius = 12
        bg.layer.cornerCurve = .continuous
        bg.translatesAutoresizingMaskIntoConstraints = false
        stack.insertSubview(bg, at: 0)
        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: stack.topAnchor),
            bg.bottomAnchor.constraint(equalTo: stack.bottomAnchor),
            bg.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: stack.trailingAnchor)
        ])

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        stack.addArrangedSubview(titleLabel)

        return stack
    }

    private func createProgressRow(label: String, count: Int, total: Int, color: UIColor) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 8
        container.alignment = .center

        let nameLabel = UILabel()
        nameLabel.text = label
        nameLabel.font = .preferredFont(forTextStyle: .subheadline)
        nameLabel.widthAnchor.constraint(equalToConstant: 140).isActive = true
        container.addArrangedSubview(nameLabel)

        let bar = UIProgressView(progressViewStyle: .default)
        bar.progressTintColor = color
        bar.progress = Float(count) / Float(total)
        container.addArrangedSubview(bar)

        let countLabel = UILabel()
        countLabel.text = "\(count)"
        countLabel.font = .preferredFont(forTextStyle: .caption1)
        countLabel.textColor = .secondaryLabel
        countLabel.textAlignment = .right
        countLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true
        container.addArrangedSubview(countLabel)

        return container
    }
}
