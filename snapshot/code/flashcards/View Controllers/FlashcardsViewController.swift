import UIKit
import Combine

class FlashcardsViewController: UIViewController {

    var deck: Deck?

    @IBOutlet var deckTitle: UILabel!
    @IBOutlet var deckStat: UILabel!
    @IBOutlet var deckDescription: UILabel!
    @IBOutlet var flashcardsTabelView: UITableView!
    @IBOutlet var tableViewHeight: NSLayoutConstraint!

    private var tokens: Set<AnyCancellable> = []
    private let schedulingService = SchedulingService(context: AppDelegate.getContext())

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(updateFlashcardData), name: .didUpdateDecks, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFlashcardData), name: .didUpdateFlashcards, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFlashcardData), name: .didCompleteStudySession, object: nil)

        setupTableView()
        updateUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        insertReviseButtonIfNeeded()
        insertExtraButtonsIfNeeded()
    }

    private var reviseButtonInserted = false

    private func insertReviseButtonIfNeeded() {
        guard !reviseButtonInserted else { return }

        // Find the storyboard "Practice" button by walking GradientButton instances
        guard let practiceButton = findGradientButton(withTitle: "Practice"),
              let container = practiceButton.superview,
              let addNewButton = findGradientButton(withTitle: "Add New") else { return }

        reviseButtonInserted = true

        let reviseButton = GradientButton(frame: .zero)
        reviseButton.translatesAutoresizingMaskIntoConstraints = false
        reviseButton.setTitle("Revise", for: .normal)
        reviseButton.setTitleColor(.white, for: .normal)
        reviseButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        reviseButton.startColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        reviseButton.endColor = UIColor(red: 0.3, green: 0.3, blue: 0.9, alpha: 1.0)
        reviseButton.cornerRadius = 10
        reviseButton.addTarget(self, action: #selector(reviseTapped), for: .touchUpInside)
        container.addSubview(reviseButton)

        // Remove old constraints between the two buttons so we can insert the third
        for constraint in container.constraints {
            let firstIsAddNew = constraint.firstItem === addNewButton
            let secondIsAddNew = constraint.secondItem === addNewButton
            let firstIsPractice = constraint.firstItem === practiceButton
            let secondIsPractice = constraint.secondItem === practiceButton

            // Remove the direct leading-trailing link between Add New and Practice
            if (firstIsAddNew || secondIsAddNew) && (firstIsPractice || secondIsPractice) {
                constraint.isActive = false
            }
            // Remove the old equal-width constraint (Practice.width = AddNew.width)
            if firstIsPractice && constraint.firstAttribute == .width && constraint.secondAttribute == .width && secondIsAddNew {
                constraint.isActive = false
            }
            // Tighten the Add New leading from >= 20 to 8
            if firstIsAddNew && constraint.firstAttribute == .leading && constraint.relation == .greaterThanOrEqual {
                constraint.isActive = false
            }
            // Tighten the Practice trailing from 16 to 8
            if secondIsPractice && constraint.firstAttribute == .trailing {
                constraint.isActive = false
            }
        }

        NSLayoutConstraint.activate([
            // Leading/trailing edges
            addNewButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            container.trailingAnchor.constraint(equalTo: practiceButton.trailingAnchor, constant: 8),

            // Chain: Add New → Revise → Practice
            reviseButton.leadingAnchor.constraint(equalTo: addNewButton.trailingAnchor, constant: 6),
            practiceButton.leadingAnchor.constraint(equalTo: reviseButton.trailingAnchor, constant: 6),

            // Equal widths
            reviseButton.widthAnchor.constraint(equalTo: addNewButton.widthAnchor),
            practiceButton.widthAnchor.constraint(equalTo: addNewButton.widthAnchor),

            // Vertical alignment
            reviseButton.topAnchor.constraint(equalTo: addNewButton.topAnchor),
            reviseButton.bottomAnchor.constraint(equalTo: addNewButton.bottomAnchor),
        ])
    }

    private var extraButtonsInserted = false

    private func insertExtraButtonsIfNeeded() {
        guard !extraButtonsInserted else { return }
        guard let practiceButton = findGradientButton(withTitle: "Practice"),
              let container = practiceButton.superview?.superview else { return }

        extraButtonsInserted = true

        let buttonsRow = UIStackView()
        buttonsRow.axis = .horizontal
        buttonsRow.spacing = 8
        buttonsRow.distribution = .fillEqually
        buttonsRow.translatesAutoresizingMaskIntoConstraints = false

        // Dashboard button
        let dashboardButton = UIButton(type: .system)
        dashboardButton.setTitle("Dashboard", for: .normal)
        dashboardButton.setImage(UIImage(systemName: "chart.bar"), for: .normal)
        dashboardButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        dashboardButton.addTarget(self, action: #selector(dashboardTapped), for: .touchUpInside)
        buttonsRow.addArrangedSubview(dashboardButton)

        // Add to container — use contentView if it's a UIVisualEffectView
        let targetView: UIView
        if let effectView = container as? UIVisualEffectView {
            targetView = effectView.contentView
        } else {
            targetView = container
        }
        targetView.addSubview(buttonsRow)

        // Position below the practice button row
        guard let practiceContainer = practiceButton.superview else { return }
        NSLayoutConstraint.activate([
            buttonsRow.topAnchor.constraint(equalTo: practiceContainer.bottomAnchor, constant: 8),
            buttonsRow.leadingAnchor.constraint(equalTo: targetView.leadingAnchor, constant: 20),
            buttonsRow.trailingAnchor.constraint(equalTo: targetView.trailingAnchor, constant: -20),
            buttonsRow.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    private func findGradientButton(withTitle title: String) -> GradientButton? {
        return findGradientButton(in: view, withTitle: title)
    }

    private func findGradientButton(in parent: UIView, withTitle title: String) -> GradientButton? {
        for subview in parent.subviews {
            if let button = subview as? GradientButton,
               button.currentTitle == title || button.configuration?.title == title {
                return button
            }
            if let found = findGradientButton(in: subview, withTitle: title) {
                return found
            }
        }
        return nil
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let swippableVC = segue.destination as? SwippableViewController, let flashcards = sender as? [Flashcard] {
            swippableVC.flashcards = flashcards
        }

        if segue.identifier == "addFlashcardSegue", let destinationVC = segue.destination as? AddNewFlashcardViewController, let deck = sender as? Deck {
            destinationVC.deck = deck
            destinationVC.flashcardService = FlashcardService(context: AppDelegate.getContext())
            destinationVC.isCreatingNewDeck = false
        }
    }

    @objc private func updateFlashcardData() {
        guard let updatedDeck = try? AppDelegate.shared.persistentContainer.viewContext.existingObject(with: deck!.objectID) as? Deck else {
            return
        }
        deck = updatedDeck
        updateUI()
    }

    func updateUI() {
        guard let deck = deck else { return }
        self.deckTitle.text = deck.deckName

        let dueCount = schedulingService.fetchDueFlashcards(for: deck).count
        let tiers = schedulingService.tierDistribution(for: deck)
        let lockedCount = schedulingService.lockedCardCount(for: deck)
        var statText = "\(tiers.tier1) T1 | \(tiers.tier2) T2 | \(tiers.tier3) T3 | \(dueCount) DUE"
        if lockedCount > 0 {
            statText += " | \(lockedCount) LOCKED"
        }
        self.deckStat.text = statText

        self.deckDescription.text = deck.deckDescription
        flashcardsTabelView.reloadData()
    }

    private func setupTableView() {
        flashcardsTabelView.delegate = self
        flashcardsTabelView.dataSource = self
        flashcardsTabelView.rowHeight = UITableView.automaticDimension
        flashcardsTabelView.estimatedRowHeight = 160
        flashcardsTabelView.publisher(for: \.contentSize)
            .sink { newContentSize in
                self.tableViewHeight.constant = newContentSize.height
            }
            .store(in: &tokens)
    }

    @IBAction func goBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func viewAllFlashcards(_ sender: Any) {
        guard let deck = deck else { return }

        let dueCards = schedulingService.fetchDueFlashcards(for: deck)

        if dueCards.isEmpty {
            // Offer early practice option
            let allCards = schedulingService.fetchEarlyPracticeCards(for: deck)

            let alert = UIAlertController(
                title: "All Caught Up!",
                message: allCards.isEmpty ? "No cards available." : "No cards are due. Practice anyway without affecting your progress?",
                preferredStyle: .alert
            )

            if !allCards.isEmpty {
                alert.addAction(UIAlertAction(title: "Practice Anyway", style: .default) { [weak self] _ in
                    let cards = Array(allCards.prefix(10))
                    self?.launchStudySession(with: cards, isEarlyPractice: true)
                })
            }

            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
            return
        }

        showRunLengthPicker(dueCards: dueCards)
    }

    private func showRunLengthPicker(dueCards: [Flashcard]) {
        let totalDue = dueCards.count

        // If 5 or fewer cards, skip the picker and start immediately
        if totalDue <= 5 {
            launchStudySession(with: dueCards, isEarlyPractice: false)
            return
        }

        let alert = UIAlertController(
            title: "How many cards?",
            message: "\(totalDue) cards due for review",
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
        guard let deck = deck else { return }

        let studySessionVC = StudySessionViewController()
        studySessionVC.deck = deck
        studySessionVC.flashcards = cards
        studySessionVC.isEarlyPractice = isEarlyPractice

        let navController = UINavigationController(rootViewController: studySessionVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    @objc private func reviseTapped() {
        guard let deck = deck else { return }

        let alert = UIAlertController(title: "Revise", message: "Choose how you'd like to review this material.", preferredStyle: .actionSheet)

        // Option 1: Original material
        let hasNotes = deck.sourceNotes != nil && !deck.sourceNotes!.isEmpty
        let notesAction = UIAlertAction(title: "Read Original Material", style: .default) { [weak self] _ in
            self?.showSourceNotes()
        }
        notesAction.isEnabled = hasNotes
        alert.addAction(notesAction)

        // Option 2: Concept overviews
        let conceptService = ConceptService(context: AppDelegate.getContext())
        let concepts = conceptService.fetchConcepts(for: deck)
        let conceptsAction = UIAlertAction(title: "Read Concept Overviews", style: .default) { [weak self] _ in
            self?.showConceptList()
        }
        conceptsAction.isEnabled = !concepts.isEmpty
        alert.addAction(conceptsAction)

        // Option 3: Browse cards
        let flashcards = (deck.flashcards?.allObjects as? [Flashcard]) ?? []
        let browseAction = UIAlertAction(title: "Browse Cards", style: .default) { [weak self] _ in
            self?.showCardBrowser()
        }
        browseAction.isEnabled = !flashcards.isEmpty
        alert.addAction(browseAction)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showSourceNotes() {
        guard let deck = deck else { return }
        let notesVC = SourceNotesViewController()
        notesVC.notesText = deck.sourceNotes ?? ""
        notesVC.deckName = deck.deckName ?? ""
        let nav = UINavigationController(rootViewController: notesVC)
        present(nav, animated: true)
    }

    private func showConceptList() {
        guard let deck = deck else { return }
        let conceptsVC = ConceptListViewController()
        conceptsVC.deck = deck
        let nav = UINavigationController(rootViewController: conceptsVC)
        present(nav, animated: true)
    }

    private func showCardBrowser() {
        guard let deck = deck,
              let flashcards = deck.flashcards?.allObjects as? [Flashcard],
              !flashcards.isEmpty else { return }

        let sorted = flashcards.sorted { $0.createdAt > $1.createdAt }
        let reviseVC = ReviseViewController()
        reviseVC.flashcards = sorted
        let navController = UINavigationController(rootViewController: reviseVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    @objc private func dashboardTapped() {
        guard let deck = deck else { return }
        let dashboardVC = DashboardViewController()
        dashboardVC.deck = deck
        let nav = UINavigationController(rootViewController: dashboardVC)
        present(nav, animated: true)
    }

    @IBAction func addFlashcardButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "addFlashcardSegue", sender: deck)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
