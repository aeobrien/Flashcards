import Foundation

struct GeneratedFlashcard {
    let question: String
    let constraints: [String]
    let bulletPoints: [String]
    let modelParagraph: String
    let backgroundContext: [String]
    let conceptName: String
    let conceptId: String
    let cardType: String
    let cardTypeRationale: String?
    let gradingRubric: GradingRubricResponse?
    let needsVerification: Bool
    let verificationNote: String?
    let sourceRefs: [String]
    let cardId: String
    let tier: Int
    let dependsOnCards: [String]
    var isSelected: Bool = true
}

struct EnrichedConcept {
    let conceptId: String
    var title: String
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
    let tier: Int
    let dependsOn: [String]
    let overview: String
    var isIncluded: Bool = true
}

struct LeitnerResult {
    let previousBox: Int16
    let newBox: Int16
    let nextReviewDate: Date
    let promoted: Bool
}
