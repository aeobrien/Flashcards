import CoreData

class SchedulingService {

    private let context: NSManagedObjectContext

    // Box intervals in days: Box 1→1 day, 2→3 days, 3→7 days, 4→14 days, 5→30 days
    static let boxIntervals: [Int16: Int] = [
        1: 1,
        2: 3,
        3: 7,
        4: 14,
        5: 30
    ]

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Fetch Due Cards (Deck)

    func fetchDueFlashcards(for deck: Deck, asOf date: Date = Date()) -> [Flashcard] {
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "deck == %@", deck),
            NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "nextReviewDate <= %@", date as NSDate),
                NSPredicate(format: "nextReviewDate == nil")
            ])
        ])

        do {
            let allDue = try context.fetch(request)
            // Filter to only available or learning cards (not locked or mastered)
            return allDue.filter { card in
                let state = card.effectiveCardState
                return state == "available" || state == "learning"
            }.shuffled()
        } catch {
            print("Error fetching due flashcards: \(error)")
            return []
        }
    }

    // MARK: - Fetch Due Cards (Group — interleaved across decks)

    func fetchDueFlashcards(for group: Group, asOf date: Date = Date()) -> [Flashcard] {
        let decks = group.decks?.allObjects as? [Deck] ?? []
        var allDue: [Flashcard] = []
        for deck in decks {
            allDue.append(contentsOf: fetchDueFlashcards(for: deck, asOf: date))
        }
        return allDue.shuffled()
    }

    // MARK: - Early Practice (non-due cards for optional study)

    func fetchEarlyPracticeCards(for deck: Deck, limit: Int = 20) -> [Flashcard] {
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "deck == %@", deck),
            NSPredicate(format: "nextReviewDate != nil")
        ])
        request.sortDescriptors = [NSSortDescriptor(key: "nextReviewDate", ascending: true)]
        request.fetchLimit = limit

        do {
            let cards = try context.fetch(request)
            return cards.filter { card in
                let state = card.effectiveCardState
                return state == "available" || state == "learning" || state == "mastered"
            }
        } catch {
            print("Error fetching early practice cards: \(error)")
            return []
        }
    }

    func fetchEarlyPracticeCards(for group: Group, limit: Int = 20) -> [Flashcard] {
        let decks = group.decks?.allObjects as? [Deck] ?? []
        var allCards: [Flashcard] = []
        for deck in decks {
            allCards.append(contentsOf: fetchEarlyPracticeCards(for: deck, limit: limit))
        }
        return allCards.sorted { ($0.nextReviewDate ?? .distantFuture) < ($1.nextReviewDate ?? .distantFuture) }
    }

    // MARK: - Grade Processing

    func processGrade(for flashcard: Flashcard, grade: Int16, reviewedAt: Date = Date()) -> LeitnerResult {
        let previousBox = flashcard.leitnerBox
        let newBox: Int16

        if grade >= 3 {
            // Minimum spacing guard: require success on a different calendar day before promoting past box 2
            if previousBox <= 2 && !hasSuccessOnDifferentDay(flashcard: flashcard, currentDate: reviewedAt) {
                // Keep in current box but update review date (forces another spaced review)
                newBox = previousBox
            } else {
                newBox = min(previousBox + 1, 5)
            }
        } else {
            newBox = 1
        }

        let intervalDays = SchedulingService.boxIntervals[newBox] ?? 1
        let nextReviewDate = Calendar.current.date(byAdding: .day, value: intervalDays, to: reviewedAt) ?? reviewedAt

        flashcard.leitnerBox = newBox
        flashcard.nextReviewDate = nextReviewDate
        flashcard.lastReviewedAt = reviewedAt
        flashcard.lastGrade = grade

        // Update card state based on new Leitner box
        if isMastered(flashcard) {
            flashcard.cardState = "mastered"
            if let deck = flashcard.deck {
                processUnlocks(for: flashcard, in: deck)
            }
        } else {
            flashcard.cardState = "learning"
        }

        AppDelegate.shared.saveContext()

        return LeitnerResult(
            previousBox: previousBox,
            newBox: newBox,
            nextReviewDate: nextReviewDate,
            promoted: newBox > previousBox
        )
    }

    /// Check if the card has been successfully reviewed (grade >= 3) on a different calendar day
    private func hasSuccessOnDifferentDay(flashcard: Flashcard, currentDate: Date) -> Bool {
        let request: NSFetchRequest<SessionResponse> = SessionResponse.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "flashcard == %@", flashcard),
            NSPredicate(format: "grade >= 3")
        ])

        do {
            let responses = try context.fetch(request)
            let currentDay = Calendar.current.startOfDay(for: currentDate)
            return responses.contains { response in
                guard let answeredAt = response.answeredAt else { return false }
                let responseDay = Calendar.current.startOfDay(for: answeredAt)
                return responseDay != currentDay
            }
        } catch {
            return false
        }
    }

    // MARK: - Stats

    func boxDistribution(for deck: Deck) -> [Int16: Int] {
        let flashcards = deck.flashcards?.allObjects as? [Flashcard] ?? []
        var distribution: [Int16: Int] = [:]
        for card in flashcards {
            distribution[card.leitnerBox, default: 0] += 1
        }
        return distribution
    }

    func nextReviewDate(for deck: Deck) -> Date? {
        let request: NSFetchRequest<Flashcard> = Flashcard.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "deck == %@", deck),
            NSPredicate(format: "nextReviewDate != nil")
        ])
        request.sortDescriptors = [NSSortDescriptor(key: "nextReviewDate", ascending: true)]
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first?.nextReviewDate
        } catch {
            return nil
        }
    }

    // MARK: - Tier Unlock Logic

    /// A card is mastered when it reaches Leitner box 3+ (2+ correct across non-consecutive sessions)
    func isMastered(_ flashcard: Flashcard) -> Bool {
        return flashcard.leitnerBox >= 3
    }

    /// Check if all prerequisites for a card have been mastered
    func arePrerequisitesMet(for flashcard: Flashcard, in deck: Deck) -> Bool {
        let prereqIds = flashcard.dependsOnCards
        guard !prereqIds.isEmpty else { return true }

        let allCards = deck.flashcards?.allObjects as? [Flashcard] ?? []
        for prereqId in prereqIds {
            guard let prereqCard = allCards.first(where: { $0.generatedCardId == prereqId }) else {
                // Prerequisite card not found — treat as not met
                return false
            }
            if !isMastered(prereqCard) {
                return false
            }
        }
        return true
    }

    /// Called after a card reaches mastered state — unlock dependent cards
    func processUnlocks(for flashcard: Flashcard, in deck: Deck) {
        guard let masteredCardId = flashcard.generatedCardId, !masteredCardId.isEmpty else { return }

        let allCards = deck.flashcards?.allObjects as? [Flashcard] ?? []

        for card in allCards {
            guard card.effectiveCardState == "locked" else { continue }
            let deps = card.dependsOnCards
            guard deps.contains(masteredCardId) else { continue }

            // Check if ALL dependencies are now mastered
            if arePrerequisitesMet(for: card, in: deck) {
                card.cardState = "available"
                card.nextReviewDate = Date()
                print("[Unlock] Card '\(card.generatedCardId ?? "")' unlocked (tier \(card.tier))")
            }
        }
    }

    // MARK: - Tier Stats

    func tierDistribution(for deck: Deck) -> (tier1: Int, tier2: Int, tier3: Int) {
        let flashcards = deck.flashcards?.allObjects as? [Flashcard] ?? []
        var t1 = 0, t2 = 0, t3 = 0
        for card in flashcards {
            switch card.tier {
            case 1: t1 += 1
            case 2: t2 += 1
            case 3: t3 += 1
            default: t1 += 1
            }
        }
        return (t1, t2, t3)
    }

    func lockedCardCount(for deck: Deck) -> Int {
        let flashcards = deck.flashcards?.allObjects as? [Flashcard] ?? []
        return flashcards.filter { $0.effectiveCardState == "locked" }.count
    }
}
