import CoreData

class ConceptService {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func findOrCreateConcept(name: String, in deck: Deck) -> Concept {
        let request: NSFetchRequest<Concept> = Concept.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "deck == %@", deck),
            NSPredicate(format: "name ==[cd] %@", name)
        ])
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            return existing
        }

        let concept = Concept(context: context)
        concept.conceptID = UUID().uuidString
        concept.name = name
        concept.deck = deck
        deck.addToConcepts(concept)
        AppDelegate.shared.saveContext()
        return concept
    }

    func findOrCreateConcept(from enriched: EnrichedConcept, in deck: Deck) -> Concept {
        let request: NSFetchRequest<Concept> = Concept.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "deck == %@", deck),
            NSPredicate(format: "name ==[cd] %@", enriched.title)
        ])
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            return existing
        }

        let concept = Concept(context: context)
        concept.conceptID = enriched.conceptId
        concept.name = enriched.title
        concept.summary = enriched.summary
        concept.importanceRationale = enriched.importanceRationale
        concept.relatedConceptIDs = enriched.relatedConcepts
        concept.relationshipNotes = enriched.relationshipNotes
        concept.needsVerification = enriched.needsVerification
        concept.verificationNote = enriched.verificationNote
        concept.contextNote = enriched.contextNote
        concept.sourceRefs = enriched.sourceRefs
        concept.userMentioned = enriched.userMentioned
        concept.userGapNote = enriched.userGapNote
        concept.tier = Int16(enriched.tier)
        concept.dependsOn = enriched.dependsOn
        concept.overview = enriched.overview
        concept.deck = deck
        deck.addToConcepts(concept)
        AppDelegate.shared.saveContext()
        return concept
    }

    func fetchConcepts(for deck: Deck) -> [Concept] {
        let request: NSFetchRequest<Concept> = Concept.fetchRequest()
        request.predicate = NSPredicate(format: "deck == %@", deck)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching concepts: \(error)")
            return []
        }
    }
}
