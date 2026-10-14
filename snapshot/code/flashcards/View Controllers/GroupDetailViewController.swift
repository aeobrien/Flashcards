import UIKit

class GroupDetailViewController: UIViewController {

    // MARK: - Properties

    var group: Group!

    private let groupService = GroupService(context: AppDelegate.getContext())
    private let schedulingService = SchedulingService(context: AppDelegate.getContext())
    private let deckService = DeckService(context: AppDelegate.getContext())

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let practiceButton = GradientButton(frame: .zero)

    private var memberDecks: [Deck] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = group.groupName ?? "Group"
        view.backgroundColor = .systemGroupedBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addDeckTapped))

        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .didUpdateGroups, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .didUpdateDecks, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .didCompleteStudySession, object: nil)

        setupUI()
        reloadData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupUI() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DeckCell")
        view.addSubview(tableView)

        practiceButton.translatesAutoresizingMaskIntoConstraints = false
        practiceButton.setTitle("Practice Group", for: .normal)
        practiceButton.setTitleColor(.white, for: .normal)
        practiceButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        practiceButton.startColor = UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0)
        practiceButton.endColor = UIColor(red: 0.4, green: 0.3, blue: 0.9, alpha: 1.0)
        practiceButton.cornerRadius = 14
        practiceButton.addTarget(self, action: #selector(practiceTapped), for: .touchUpInside)
        view.addSubview(practiceButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: practiceButton.topAnchor, constant: -12),

            practiceButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            practiceButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            practiceButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            practiceButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Data

    @objc private func reloadData() {
        memberDecks = group.sortedDecks
        tableView.reloadData()
    }

    // MARK: - Actions

    @objc private func addDeckTapped() {
        let allDecks = deckService.fetchAllDecks()
        let currentDeckIDs = Set(memberDecks.compactMap { $0.deckID })
        let available = allDecks.filter { !currentDeckIDs.contains($0.deckID ?? "") }

        if available.isEmpty {
            Alert.showAlert(on: self, title: "No Available Decks", message: "All decks are already in this group, or no decks exist yet.")
            return
        }

        let alert = UIAlertController(title: "Add Deck to Group", message: nil, preferredStyle: .actionSheet)
        for deck in available {
            alert.addAction(UIAlertAction(title: deck.deckName ?? "Untitled", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.groupService.addDeck(deck, to: self.group)
                NotificationCenter.default.post(name: .didUpdateGroups, object: nil)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func practiceTapped() {
        let dueCards = schedulingService.fetchDueFlashcards(for: group)

        if dueCards.isEmpty {
            // Offer early practice
            let allCards = schedulingService.fetchEarlyPracticeCards(for: group)
            if allCards.isEmpty {
                Alert.showAlert(on: self, title: "No Cards", message: "Add decks with flashcards to this group first.")
                return
            }

            let alert = UIAlertController(
                title: "All Caught Up!",
                message: "No cards are due. Practice anyway without affecting your progress?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Practice Anyway", style: .default) { [weak self] _ in
                let cards = Array(allCards.prefix(10))
                self?.launchStudySession(with: cards, isEarlyPractice: true)
            })
            present(alert, animated: true)
            return
        }

        showRunLengthPicker(dueCards: dueCards)
    }

    private func showRunLengthPicker(dueCards: [Flashcard]) {
        let totalDue = dueCards.count

        if totalDue <= 5 {
            launchStudySession(with: dueCards, isEarlyPractice: false)
            return
        }

        let alert = UIAlertController(
            title: "How many cards?",
            message: "\(totalDue) cards due across \(memberDecks.count) decks",
            preferredStyle: .actionSheet
        )

        let options = [5, 10, 15, 25].filter { $0 < totalDue }
        for count in options {
            alert.addAction(UIAlertAction(title: "\(count) cards", style: .default) { [weak self] _ in
                let selected = Array(dueCards.shuffled().prefix(count))
                self?.launchStudySession(with: selected, isEarlyPractice: false)
            })
        }

        alert.addAction(UIAlertAction(title: "All \(totalDue) cards", style: .default) { [weak self] _ in
            self?.launchStudySession(with: dueCards, isEarlyPractice: false)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func launchStudySession(with cards: [Flashcard], isEarlyPractice: Bool) {
        let studySessionVC = StudySessionViewController()
        studySessionVC.group = group
        studySessionVC.flashcards = cards
        studySessionVC.isEarlyPractice = isEarlyPractice

        let navController = UINavigationController(rootViewController: studySessionVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
}

// MARK: - UITableViewDelegate & DataSource

extension GroupDetailViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Decks"
        case 1: return "Stats"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return max(memberDecks.count, 1)
        case 1: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeckCell", for: indexPath)

        if indexPath.section == 0 {
            if memberDecks.isEmpty {
                var config = cell.defaultContentConfiguration()
                config.text = "No decks yet"
                config.textProperties.color = .secondaryLabel
                cell.contentConfiguration = config
                cell.accessoryType = .none
            } else {
                let deck = memberDecks[indexPath.row]
                let dueCount = schedulingService.fetchDueFlashcards(for: deck).count
                let totalCount = deck.flashcards?.count ?? 0

                var config = cell.defaultContentConfiguration()
                config.text = deck.deckName ?? "Untitled"
                config.secondaryText = "\(totalCount) cards, \(dueCount) due"
                config.image = UIImage(systemName: "rectangle.stack.fill")
                cell.contentConfiguration = config
                cell.accessoryType = .disclosureIndicator
            }
        } else {
            let totalCards = memberDecks.reduce(0) { $0 + (($1.flashcards?.count ?? 0)) }
            let totalDue = memberDecks.reduce(0) { $0 + schedulingService.fetchDueFlashcards(for: $1).count }

            var config = cell.defaultContentConfiguration()
            config.text = "Dashboard"
            config.secondaryText = "\(totalCards) total cards, \(totalDue) due"
            config.image = UIImage(systemName: "chart.bar")
            cell.contentConfiguration = config
            cell.accessoryType = .disclosureIndicator
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 && !memberDecks.isEmpty {
            let deck = memberDecks[indexPath.row]
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let flashcardsVC = storyboard.instantiateViewController(withIdentifier: "FlashcardsViewController") as? FlashcardsViewController {
                flashcardsVC.deck = deck
                flashcardsVC.modalPresentationStyle = .fullScreen
                flashcardsVC.modalTransitionStyle = .crossDissolve
                present(flashcardsVC, animated: true)
            }
        } else if indexPath.section == 1 {
            let dashboardVC = DashboardViewController()
            dashboardVC.group = group
            navigationController?.pushViewController(dashboardVC, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 && !memberDecks.isEmpty
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && indexPath.section == 0 {
            let deck = memberDecks[indexPath.row]
            groupService.removeDeck(deck, from: group)
            NotificationCenter.default.post(name: .didUpdateGroups, object: nil)
        }
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Remove"
    }
}
