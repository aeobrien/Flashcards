import Foundation
import CoreData

extension Concept {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Concept> {
        return NSFetchRequest<Concept>(entityName: "Concept")
    }

    @NSManaged public var conceptID: String?
    @NSManaged public var name: String?
    @NSManaged public var summary: String?
    @NSManaged public var importanceRationale: String?
    @NSManaged public var relatedConceptIDsJSON: String?
    @NSManaged public var relationshipNotes: String?
    @NSManaged public var needsVerification: Bool
    @NSManaged public var verificationNote: String?
    @NSManaged public var contextNote: String?
    @NSManaged public var sourceRefsJSON: String?
    @NSManaged public var userMentioned: String?
    @NSManaged public var tier: Int16
    @NSManaged public var dependsOnJSON: String?
    @NSManaged public var userGapNote: String?
    @NSManaged public var overview: String?
    @NSManaged public var deck: Deck?
    @NSManaged public var flashcards: NSSet?

    // MARK: - JSON Computed Properties

    var relatedConceptIDs: [String] {
        get {
            guard let json = relatedConceptIDsJSON,
                  let data = json.data(using: .utf8),
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return array
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                relatedConceptIDsJSON = json
            }
        }
    }

    var sourceRefs: [String] {
        get {
            guard let json = sourceRefsJSON,
                  let data = json.data(using: .utf8),
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return array
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                sourceRefsJSON = json
            }
        }
    }

    var dependsOn: [String] {
        get {
            guard let json = dependsOnJSON,
                  let data = json.data(using: .utf8),
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return array
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                dependsOnJSON = json
            }
        }
    }
}

// MARK: Generated accessors for flashcards
extension Concept {

    @objc(addFlashcardsObject:)
    @NSManaged public func addToFlashcards(_ value: Flashcard)

    @objc(removeFlashcardsObject:)
    @NSManaged public func removeFromFlashcards(_ value: Flashcard)

    @objc(addFlashcards:)
    @NSManaged public func addToFlashcards(_ values: NSSet)

    @objc(removeFlashcards:)
    @NSManaged public func removeFromFlashcards(_ values: NSSet)
}

extension Concept: Identifiable {

}
