import Foundation
import CoreData

extension Deck {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Deck> {
        return NSFetchRequest<Deck>(entityName: "Deck")
    }

    @NSManaged public var deckDescription: String?
    @NSManaged public var deckID: String?
    @NSManaged public var deckName: String?
    @NSManaged public var lastViewed: Date?
    @NSManaged public var isFavourited: Bool
    @NSManaged public var totalCards: Int16
    @NSManaged public var flashcards: NSSet?
    @NSManaged public var createdAt: Date?
    @NSManaged public var studySessions: NSSet?
    @NSManaged public var concepts: NSSet?
    @NSManaged public var sourceDescription: String?
    @NSManaged public var sourceNotes: String?
    @NSManaged public var group: Group?

    public var completedCount: Int {
        let set = flashcards as? Set<Flashcard> ?? []
        return set.filter { $0.status == "completed" }.count
    }
}

// MARK: Generated accessors for flashcards
extension Deck {

    @objc(addFlashcardsObject:)
    @NSManaged public func addToFlashcards(_ value: Flashcard)

    @objc(removeFlashcardsObject:)
    @NSManaged public func removeFromFlashcards(_ value: Flashcard)

    @objc(addFlashcards:)
    @NSManaged public func addToFlashcards(_ values: NSSet)

    @objc(removeFlashcards:)
    @NSManaged public func removeFromFlashcards(_ values: NSSet)
}

// MARK: Generated accessors for studySessions
extension Deck {

    @objc(addStudySessionsObject:)
    @NSManaged public func addToStudySessions(_ value: StudySession)

    @objc(removeStudySessionsObject:)
    @NSManaged public func removeFromStudySessions(_ value: StudySession)

    @objc(addStudySessions:)
    @NSManaged public func addToStudySessions(_ values: NSSet)

    @objc(removeStudySessions:)
    @NSManaged public func removeFromStudySessions(_ values: NSSet)
}

// MARK: Generated accessors for concepts
extension Deck {

    @objc(addConceptsObject:)
    @NSManaged public func addToConcepts(_ value: Concept)

    @objc(removeConceptsObject:)
    @NSManaged public func removeFromConcepts(_ value: Concept)

    @objc(addConcepts:)
    @NSManaged public func addToConcepts(_ values: NSSet)

    @objc(removeConcepts:)
    @NSManaged public func removeFromConcepts(_ values: NSSet)
}

extension Deck: Identifiable {

}
