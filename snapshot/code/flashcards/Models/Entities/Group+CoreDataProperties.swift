import Foundation
import CoreData

extension Group {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Group> {
        return NSFetchRequest<Group>(entityName: "Group")
    }

    @NSManaged public var groupID: String?
    @NSManaged public var groupName: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var decks: NSSet?
    @NSManaged public var studySessions: NSSet?

    var sortedDecks: [Deck] {
        let set = decks as? Set<Deck> ?? []
        return set.sorted { ($0.deckName ?? "") < ($1.deckName ?? "") }
    }
}

// MARK: Generated accessors for decks
extension Group {

    @objc(addDecksObject:)
    @NSManaged public func addToDecks(_ value: Deck)

    @objc(removeDecksObject:)
    @NSManaged public func removeFromDecks(_ value: Deck)

    @objc(addDecks:)
    @NSManaged public func addToDecks(_ values: NSSet)

    @objc(removeDecks:)
    @NSManaged public func removeFromDecks(_ values: NSSet)
}

// MARK: Generated accessors for studySessions
extension Group {

    @objc(addStudySessionsObject:)
    @NSManaged public func addToStudySessions(_ value: StudySession)

    @objc(removeStudySessionsObject:)
    @NSManaged public func removeFromStudySessions(_ value: StudySession)

    @objc(addStudySessions:)
    @NSManaged public func addToStudySessions(_ values: NSSet)

    @objc(removeStudySessions:)
    @NSManaged public func removeFromStudySessions(_ values: NSSet)
}

extension Group: Identifiable {

}
