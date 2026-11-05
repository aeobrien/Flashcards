import Foundation

// MARK: - Concept Extraction (Phase 1)

struct ConceptExtractionResponse: Codable {
    let deckTitle: String
    let sourceDescription: String
    let concepts: [ExtractedConcept]
    let extractionReport: ExtractionReport?

    enum CodingKeys: String, CodingKey {
        case deckTitle = "deck_title"
        case sourceDescription = "source_description"
        case concepts
        case extractionReport = "extraction_report"
    }
}

struct ExtractedConcept: Codable {
    let conceptId: String
    let title: String
    let summary: String
    let importanceRationale: String
    let relatedConcepts: [String]
    let relationshipNotes: String
    let needsVerification: Bool
    let verificationNote: String?
    let contextNote: String?
    let sourceRefs: [String]
    let userMentioned: String?
    let userGapNote: String?
    let tier: Int?
    let dependsOn: [String]?
    let overview: String?

    enum CodingKeys: String, CodingKey {
        case conceptId = "concept_id"
        case title
        case summary
        case importanceRationale = "importance_rationale"
        case relatedConcepts = "related_concepts"
        case relationshipNotes = "relationship_notes"
        case needsVerification = "needs_verification"
        case verificationNote = "verification_note"
        case contextNote = "context_note"
        case sourceRefs = "source_refs"
        case userMentioned = "user_mentioned"
        case userGapNote = "user_gap_note"
        case tier
        case dependsOn = "depends_on"
        case overview
    }
}

struct TierBreakdown: Codable {
    let tier1: Int?
    let tier2: Int?
    let tier3: Int?

    enum CodingKeys: String, CodingKey {
        case tier1 = "tier_1"
        case tier2 = "tier_2"
        case tier3 = "tier_3"
    }
}

struct ExtractionReport: Codable {
    let conceptCount: Int
    let verificationFlags: Int
    let notesOnOmissions: [String]
    let tierBreakdown: TierBreakdown?

    enum CodingKeys: String, CodingKey {
        case conceptCount = "concept_count"
        case verificationFlags = "verification_flags"
        case notesOnOmissions = "notes_on_omissions"
        case tierBreakdown = "tier_breakdown"
    }
}

// MARK: - Card Generation (Phase 2)

struct CardGenerationResponse: Codable {
    let batchInfo: BatchInfo?
    let cards: [GeneratedCardResponse]
    let batchReport: BatchReport?

    enum CodingKeys: String, CodingKey {
        case batchInfo = "batch_info"
        case cards
        case batchReport = "batch_report"
    }
}

struct BatchInfo: Codable {
    let conceptCount: Int?
    let cardCount: Int?

    enum CodingKeys: String, CodingKey {
        case conceptCount = "concept_count"
        case cardCount = "card_count"
    }
}

struct GeneratedCardResponse: Codable {
    let cardId: String?
    let conceptId: String
    let cardType: String
    let cardTypeRationale: String?
    let front: CardFront
    let back: CardBack
    let gradingRubric: GradingRubricResponse?
    let needsVerification: Bool?
    let verificationNote: String?
    let sourceRefs: [String]?
    let tier: Int?
    let dependsOnCards: [String]?

    enum CodingKeys: String, CodingKey {
        case cardId = "card_id"
        case conceptId = "concept_id"
        case cardType = "card_type"
        case cardTypeRationale = "card_type_rationale"
        case front, back
        case gradingRubric = "grading_rubric"
        case needsVerification = "needs_verification"
        case verificationNote = "verification_note"
        case sourceRefs = "source_refs"
        case tier
        case dependsOnCards = "depends_on_cards"
    }
}

struct CardFront: Codable {
    let question: String
    let constraints: [String]?
}

struct CardBack: Codable {
    let idealAnswerBullets: [String]
    let modelAnswerParagraph: String
    let backgroundContext: [String]?

    enum CodingKeys: String, CodingKey {
        case idealAnswerBullets = "ideal_answer_bullets"
        case modelAnswerParagraph = "model_answer_paragraph"
        case backgroundContext = "background_context"
    }
}

struct GradingRubricResponse: Codable {
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

struct BatchReport: Codable {
    let totalCards: Int?
    let cardTypeSummary: [String: Int]?
    let tierBreakdown: TierBreakdown?

    enum CodingKeys: String, CodingKey {
        case totalCards = "total_cards"
        case cardTypeSummary = "card_type_summary"
        case tierBreakdown = "tier_breakdown"
    }
}

// MARK: - Grading

struct GradingResponse: Codable {
    let grade: Int
    let feedback: String
    let bulletPointsHit: [Bool]

    enum CodingKeys: String, CodingKey {
        case grade
        case feedback
        case bulletPointsHit = "bullet_points_hit"
    }
}
