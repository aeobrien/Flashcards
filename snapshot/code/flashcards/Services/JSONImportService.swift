import Foundation
import CoreData

// MARK: - Import JSON Models

enum ImportType: String {
    case cards
    case deck
    case group
}

struct ImportRoot: Codable {
    let type: String // "cards", "deck", or "group"
    let cards: [ImportCard]?
    let deck: ImportDeck?
    let group: ImportGroup?
}

struct ImportGroup: Codable {
    let name: String
    let decks: [ImportDeck]
}

struct ImportDeck: Codable {
    let name: String
    let description: String?
    let sourceNotes: String?
    let concepts: [ImportConcept]?
    let cards: [ImportCard]

    enum CodingKeys: String, CodingKey {
        case name, description, concepts, cards
        case sourceNotes = "source_notes"
    }
}

struct ImportConcept: Codable {
    let conceptId: String
    let name: String
    let summary: String?
    let importanceRationale: String?
    let relatedConcepts: [String]?
    let relationshipNotes: String?
    let tier: Int?
    let dependsOn: [String]?
    let overview: String?

    enum CodingKeys: String, CodingKey {
        case name, summary, overview, tier
        case conceptId = "concept_id"
        case importanceRationale = "importance_rationale"
        case relatedConcepts = "related_concepts"
        case relationshipNotes = "relationship_notes"
        case dependsOn = "depends_on"
    }
}

struct ImportCard: Codable {
    let conceptId: String?
    let cardType: String?
    let question: String
    let answer: String?
    let bulletPoints: [String]?
    let modelParagraph: String?
    let constraints: [String]?
    let backgroundContext: [String]?
    let gradingRubric: ImportGradingRubric?
    let tier: Int?
    let cardId: String?
    let dependsOnCards: [String]?
    let sourceRefs: [String]?

    enum CodingKeys: String, CodingKey {
        case question, answer, constraints, tier
        case conceptId = "concept_id"
        case cardType = "card_type"
        case bulletPoints = "bullet_points"
        case modelParagraph = "model_paragraph"
        case backgroundContext = "background_context"
        case gradingRubric = "grading_rubric"
        case cardId = "card_id"
        case dependsOnCards = "depends_on_cards"
        case sourceRefs = "source_refs"
    }
}

struct ImportGradingRubric: Codable {
    let mustContainKeywords: [String]?
    let coreMeaning: String?
    let structuralTruths: [String]?
    let commonMisconceptions: String?

    enum CodingKeys: String, CodingKey {
        case mustContainKeywords = "must_contain_keywords"
        case coreMeaning = "core_meaning"
        case structuralTruths = "structural_truths"
        case commonMisconceptions = "common_misconceptions"
    }
}

// MARK: - Import Result

struct ImportResult {
    let decksCreated: Int
    let cardsCreated: Int
    let groupCreated: Bool
    let message: String
}

// MARK: - Import Errors

enum JSONImportError: LocalizedError {
    case invalidJSON(String)
    case unknownType(String)
    case missingData(String)
    case coreDataError(String)

    var errorDescription: String? {
        switch self {
        case .invalidJSON(let detail): return "Invalid JSON: \(detail)"
        case .unknownType(let type): return "Unknown import type: '\(type)'. Expected 'cards', 'deck', or 'group'."
        case .missingData(let detail): return "Missing data: \(detail)"
        case .coreDataError(let detail): return "Database error: \(detail)"
        }
    }
}

// MARK: - Import Service

class JSONImportService {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Public API

    func detectImportType(from data: Data) throws -> ImportType {
        let root = try decodeRoot(from: data)
        guard let type = ImportType(rawValue: root.type) else {
            throw JSONImportError.unknownType(root.type)
        }
        return type
    }

    func importCards(from data: Data, into deck: Deck) throws -> ImportResult {
        let root = try decodeRoot(from: data)
        guard let cards = root.cards, !cards.isEmpty else {
            throw JSONImportError.missingData("No cards found in JSON.")
        }
        let count = persistCards(cards, into: deck, concepts: nil)
        postNotifications()
        return ImportResult(decksCreated: 0, cardsCreated: count, groupCreated: false,
                            message: "Imported \(count) card\(count == 1 ? "" : "s") into \(deck.deckName ?? "deck").")
    }

    func importDeck(from data: Data) throws -> ImportResult {
        let root = try decodeRoot(from: data)
        guard let importDeck = root.deck else {
            throw JSONImportError.missingData("No deck found in JSON.")
        }
        let (deck, cardCount) = persistDeck(importDeck)
        _ = deck // used via persistDeck
        postNotifications()
        return ImportResult(decksCreated: 1, cardsCreated: cardCount, groupCreated: false,
                            message: "Imported deck '\(importDeck.name)' with \(cardCount) card\(cardCount == 1 ? "" : "s").")
    }

    func importGroup(from data: Data) throws -> ImportResult {
        let root = try decodeRoot(from: data)
        guard let importGroup = root.group else {
            throw JSONImportError.missingData("No group found in JSON.")
        }

        let groupService = GroupService(context: context)
        let group = groupService.createGroup(name: importGroup.name)

        var totalCards = 0
        for importDeck in importGroup.decks {
            let (deck, cardCount) = persistDeck(importDeck)
            groupService.addDeck(deck, to: group)
            totalCards += cardCount
        }

        postNotifications()
        let deckCount = importGroup.decks.count
        return ImportResult(decksCreated: deckCount, cardsCreated: totalCards, groupCreated: true,
                            message: "Imported group '\(importGroup.name)' with \(deckCount) deck\(deckCount == 1 ? "" : "s") and \(totalCards) card\(totalCards == 1 ? "" : "s").")
    }

    // MARK: - Internal

    private func decodeRoot(from data: Data) throws -> ImportRoot {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(ImportRoot.self, from: data)
        } catch {
            throw JSONImportError.invalidJSON(error.localizedDescription)
        }
    }

    private func persistDeck(_ importDeck: ImportDeck) -> (Deck, Int) {
        let deckService = DeckService(context: context)
        let deck = deckService.createDeck(deckName: importDeck.name, description: importDeck.description ?? "")
        deck.sourceNotes = importDeck.sourceNotes

        var conceptMap: [String: Concept]? = nil
        if let importConcepts = importDeck.concepts, !importConcepts.isEmpty {
            conceptMap = persistConcepts(importConcepts, into: deck)
        }

        let cardCount = persistCards(importDeck.cards, into: deck, concepts: conceptMap)
        deck.totalCards = Int16(cardCount)
        AppDelegate.shared.saveContext()
        return (deck, cardCount)
    }

    private func persistConcepts(_ importConcepts: [ImportConcept], into deck: Deck) -> [String: Concept] {
        var map: [String: Concept] = [:]
        for ic in importConcepts {
            let concept = Concept(context: context)
            concept.conceptID = ic.conceptId
            concept.name = ic.name
            concept.summary = ic.summary
            concept.importanceRationale = ic.importanceRationale
            concept.relatedConceptIDs = ic.relatedConcepts ?? []
            concept.relationshipNotes = ic.relationshipNotes
            concept.tier = Int16(ic.tier ?? 1)
            concept.dependsOn = ic.dependsOn ?? []
            concept.overview = ic.overview
            concept.deck = deck
            deck.addToConcepts(concept)
            map[ic.conceptId] = concept
        }
        AppDelegate.shared.saveContext()
        return map
    }

    @discardableResult
    private func persistCards(_ cards: [ImportCard], into deck: Deck, concepts: [String: Concept]?) -> Int {
        let flashcardService = FlashcardService(context: context)
        var count = 0

        for card in cards {
            let concept: Concept?
            if let cid = card.conceptId, let concepts = concepts {
                concept = concepts[cid]
            } else if let cid = card.conceptId {
                let conceptService = ConceptService(context: context)
                concept = conceptService.findOrCreateConcept(name: cid, in: deck)
            } else {
                concept = nil
            }

            let rubric: GradingRubric?
            if let ir = card.gradingRubric {
                rubric = GradingRubric(
                    mustContainKeywords: ir.mustContainKeywords ?? [],
                    coreMeaning: ir.coreMeaning ?? "",
                    structuralTruths: ir.structuralTruths,
                    commonMisconceptions: ir.commonMisconceptions ?? ""
                )
            } else {
                rubric = nil
            }

            let backDesc = card.answer ?? card.modelParagraph ?? ""
            let bullets = card.bulletPoints ?? (card.answer.map { [$0] } ?? [])
            let model = card.modelParagraph ?? card.answer ?? ""

            flashcardService.addFlashcard(
                to: deck,
                frontLabel: card.question,
                backDescription: backDesc,
                bulletPoints: bullets,
                modelParagraph: model,
                concept: concept,
                cardType: card.cardType,
                constraints: card.constraints,
                backgroundContext: card.backgroundContext,
                gradingRubric: rubric,
                sourceRefs: card.sourceRefs,
                tier: Int16(card.tier ?? 1),
                dependsOnCards: card.dependsOnCards ?? [],
                generatedCardId: card.cardId
            )
            count += 1
        }

        deck.totalCards = Int16((deck.flashcards?.count ?? 0))
        AppDelegate.shared.saveContext()
        return count
    }

    private func postNotifications() {
        NotificationCenter.default.post(name: .didUpdateDecks, object: nil)
        NotificationCenter.default.post(name: .didUpdateFlashcards, object: nil)
        NotificationCenter.default.post(name: .didUpdateGroups, object: nil)
    }
}
