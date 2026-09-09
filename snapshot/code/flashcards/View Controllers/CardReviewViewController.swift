import UIKit

class CardReviewViewController: UIViewController {

    // MARK: - Properties

    var deckName: String = ""
    var sourceDescription: String = ""
    var originalNotes: String = ""
    var enrichedConcepts: [EnrichedConcept] = []
    var generatedCards: [GeneratedFlashcard] = []

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let saveButton = GradientButton(frame: .zero)
    private let selectAllButton = UIBarButtonItem()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Review Cards"
        view.backgroundColor = .systemBackground

        selectAllButton.title = "Deselect All"
        selectAllButton.target = self
        selectAllButton.action = #selector(toggleSelectAll)
        navigationItem.rightBarButtonItem = selectAllButton

        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(GeneratedCardTableViewCell.self, forCellReuseIdentifier: "GeneratedCardCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        view.addSubview(tableView)

        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("Save to Deck", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        saveButton.startColor = UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0)
        saveButton.endColor = UIColor(red: 0.4, green: 0.3, blue: 0.9, alpha: 1.0)
        saveButton.cornerRadius = 14
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        view.addSubview(saveButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -12),

            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Actions

    @objc private func toggleSelectAll() {
        let allSelected = generatedCards.allSatisfy { $0.isSelected }
        for i in generatedCards.indices {
            generatedCards[i].isSelected = !allSelected
        }
        selectAllButton.title = allSelected ? "Select All" : "Deselect All"
        tableView.reloadData()
    }

    @objc private func saveTapped() {
        let log = DebugLogService.shared

        let selectedCards = generatedCards.filter { $0.isSelected }
        guard !selectedCards.isEmpty else {
            Alert.showAlert(on: self, title: "No Cards Selected", message: "Please select at least one card to save.")
            return
        }

        log.log("Save started: \(selectedCards.count) selected cards, deck='\(deckName)'")

        // Build concept lookup — use safe initializer to handle duplicate IDs
        var conceptLookup: [String: EnrichedConcept] = [:]
        for concept in enrichedConcepts {
            conceptLookup[concept.conceptId] = concept
        }

        // Check for missing dependencies — auto-include prerequisite concepts
        let selectedConceptIds = Set(selectedCards.map { $0.conceptId })
        var autoIncludedNames: [String] = []
        var cardsToSave = selectedCards

        for card in selectedCards {
            guard let enriched = conceptLookup[card.conceptId] else { continue }
            for depId in enriched.dependsOn {
                if !selectedConceptIds.contains(depId) {
                    let alreadyIncluded = cardsToSave.contains { $0.conceptId == depId }
                    if !alreadyIncluded {
                        let depCards = generatedCards.filter { $0.conceptId == depId && $0.tier == 1 }
                        if !depCards.isEmpty {
                            cardsToSave.append(contentsOf: depCards)
                            if let depConcept = conceptLookup[depId] {
                                autoIncludedNames.append(depConcept.title)
                            }
                        }
                    }
                }
            }
        }

        if !autoIncludedNames.isEmpty {
            let names = autoIncludedNames.joined(separator: ", ")
            log.log("Auto-included prerequisite concepts: \(names)")
            Alert.showAlert(on: self, title: "Prerequisites Added", message: "Basic cards for \(names) have been added as prerequisites for your selected concepts.")
        }

        // Save recovery file BEFORE attempting Core Data save
        log.log("Writing recovery file for \(cardsToSave.count) cards...")
        DebugLogService.shared.saveRecoveryData(
            cards: cardsToSave,
            deckName: deckName,
            sourceDescription: sourceDescription,
            concepts: enrichedConcepts
        )

        // Core Data save with error handling
        let context = AppDelegate.getContext()
        let deckService = DeckService(context: context)
        let flashcardService = FlashcardService(context: context)
        let conceptService = ConceptService(context: context)

        let deck = deckService.createDeck(deckName: deckName, description: sourceDescription.isEmpty ? "AI-generated deck" : sourceDescription)
        deck.sourceDescription = sourceDescription
        deck.sourceNotes = originalNotes
        log.log("Deck created: '\(deckName)'")

        var savedCount = 0
        for card in cardsToSave {
            let concept: Concept
            if let enriched = conceptLookup[card.conceptId] {
                concept = conceptService.findOrCreateConcept(from: enriched, in: deck)
            } else {
                concept = conceptService.findOrCreateConcept(name: card.conceptName, in: deck)
            }

            let rubric: GradingRubric? = card.gradingRubric.map {
                GradingRubric(
                    mustContainKeywords: $0.mustContainKeywords ?? [],
                    coreMeaning: $0.coreMeaning ?? "",
                    structuralTruths: $0.structuralTruths,
                    commonMisconceptions: $0.commonMisconceptions ?? ""
                )
            }

            flashcardService.addFlashcard(
                to: deck,
                frontLabel: card.question,
                backDescription: card.bulletPoints.joined(separator: "\n"),
                bulletPoints: card.bulletPoints,
                modelParagraph: card.modelParagraph,
                concept: concept,
                cardType: card.cardType,
                constraints: card.constraints,
                backgroundContext: card.backgroundContext,
                gradingRubric: rubric,
                sourceRefs: card.sourceRefs,
                needsVerification: card.needsVerification,
                verificationNote: card.verificationNote,
                tier: Int16(card.tier),
                dependsOnCards: card.dependsOnCards,
                generatedCardId: card.cardId
            )
            savedCount += 1
        }

        // Final save to ensure everything is persisted
        let success = AppDelegate.shared.saveContext()

        if success {
            log.log("Save completed successfully: \(savedCount) cards saved to deck '\(deckName)'")
            DebugLogService.shared.deleteRecoveryFile()
            NotificationCenter.default.post(name: .didUpdateDecks, object: nil)
            dismiss(animated: true)
        } else {
            log.log("Final Core Data save failed after creating \(savedCount) cards", level: .error)
            // Roll back the failed context to avoid inconsistent state
            context.rollback()
            Alert.showAlert(
                on: self,
                title: "Save Failed",
                message: "Cards could not be saved to the database. Your cards have been backed up — you can recover them from Settings > Debug."
            )
        }
    }

    // MARK: - Grouped by concept

    private var groupedCards: [(concept: String, cards: [(index: Int, card: GeneratedFlashcard)])] {
        var dict: [String: [(index: Int, card: GeneratedFlashcard)]] = [:]
        for (index, card) in generatedCards.enumerated() {
            dict[card.conceptName, default: []].append((index, card))
        }
        return dict.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }
}

// MARK: - UITableViewDelegate & DataSource

extension CardReviewViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return groupedCards.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let group = groupedCards[section]
        let tier = group.cards.first?.card.tier ?? 1
        return "\(group.concept) (T\(tier))"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupedCards[section].cards.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GeneratedCardCell", for: indexPath) as! GeneratedCardTableViewCell
        let group = groupedCards[indexPath.section]
        let item = group.cards[indexPath.row]
        let card = item.card

        cell.configure(
            question: card.question,
            conceptName: card.conceptName,
            cardType: card.cardType,
            constraints: card.constraints,
            bulletPoints: card.bulletPoints,
            isSelected: card.isSelected,
            tier: card.tier
        )

        cell.onCheckboxToggle = { [weak self] isChecked in
            self?.generatedCards[item.index].isSelected = isChecked
        }

        return cell
    }
}
