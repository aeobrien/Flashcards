import CoreData

class FlashcardService {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - CRUD Operations for Flashcard

    func addFlashcard(to deck: Deck, flashcardID: String, frontLabel: String, backDescription: String, status: String) {
        let newFlashcard = Flashcard(context: context)
        newFlashcard.flashcardID = flashcardID
        newFlashcard.frontLabel = frontLabel
        newFlashcard.backDescription = backDescription
        newFlashcard.status = status
        newFlashcard.createdAt = Date()
        newFlashcard.leitnerBox = 1
        newFlashcard.nextReviewDate = Date()

        deck.addToFlashcards(newFlashcard)
        AppDelegate.shared.saveContext()
    }

    func addFlashcard(to deck: Deck,
                      frontLabel: String,
                      backDescription: String,
                      bulletPoints: [String],
                      modelParagraph: String,
                      concept: Concept?,
                      cardType: String? = nil,
                      constraints: [String]? = nil,
                      backgroundContext: [String]? = nil,
                      gradingRubric: GradingRubric? = nil,
                      sourceRefs: [String]? = nil,
                      needsVerification: Bool = false,
                      verificationNote: String? = nil,
                      tier: Int16 = 1,
                      dependsOnCards: [String] = [],
                      cardState: String? = nil,
                      generatedCardId: String? = nil) {
        let newFlashcard = Flashcard(context: context)
        newFlashcard.flashcardID = UUID().uuidString
        newFlashcard.frontLabel = frontLabel
        newFlashcard.backDescription = backDescription
        newFlashcard.bulletPoints = bulletPoints
        newFlashcard.modelParagraph = modelParagraph
        newFlashcard.status = "pending"
        newFlashcard.createdAt = Date()
        newFlashcard.leitnerBox = 1
        newFlashcard.nextReviewDate = Date()
        newFlashcard.concept = concept
        newFlashcard.cardType = cardType
        if let constraints = constraints {
            newFlashcard.constraints = constraints
        }
        if let bgContext = backgroundContext {
            newFlashcard.backgroundContext = bgContext
        }
        newFlashcard.gradingRubric = gradingRubric
        if let refs = sourceRefs {
            newFlashcard.sourceRefs = refs
        }
        newFlashcard.needsVerification = needsVerification
        newFlashcard.verificationNote = verificationNote
        newFlashcard.tier = tier
        newFlashcard.dependsOnCards = dependsOnCards
        newFlashcard.generatedCardId = generatedCardId
        // Tier 1 cards are immediately available; higher tiers start locked
        newFlashcard.cardState = cardState ?? (tier <= 1 ? "available" : "locked")

        deck.addToFlashcards(newFlashcard)
        AppDelegate.shared.saveContext()
    }

    func updateGrade(for flashcard: Flashcard, grade: Int16) {
        flashcard.lastGrade = grade
        AppDelegate.shared.saveContext()
    }

    func updateLeitnerBox(for flashcard: Flashcard, newBox: Int16, nextReviewDate: Date) {
        flashcard.leitnerBox = newBox
        flashcard.nextReviewDate = nextReviewDate
        AppDelegate.shared.saveContext()
    }

    func markReviewed(flashcard: Flashcard, grade: Int16, reviewDate: Date) {
        flashcard.lastGrade = grade
        flashcard.lastReviewedAt = reviewDate
        AppDelegate.shared.saveContext()
    }

    func deleteFlashcard(_ flashcard: Flashcard) {
        context.delete(flashcard)
        AppDelegate.shared.saveContext()
    }
}
