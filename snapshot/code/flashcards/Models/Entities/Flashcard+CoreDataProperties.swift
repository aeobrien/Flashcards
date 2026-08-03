import Foundation
import CoreData

struct GradingRubric: Codable {
    let mustContainKeywords: [String]
    let coreMeaning: String
    let structuralTruths: [String]?
    let commonMisconceptions: String
}

extension Flashcard {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Flashcard> {
        return NSFetchRequest<Flashcard>(entityName: "Flashcard")
    }

    @NSManaged public var backDescription: String?
    @NSManaged public var flashcardID: String?
    @NSManaged public var frontLabel: String?
    @NSManaged public var status: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var bulletPointsJSON: String?
    @NSManaged public var modelParagraph: String?
    @NSManaged public var lastGrade: Int16
    @NSManaged public var nextReviewDate: Date?
    @NSManaged public var leitnerBox: Int16
    @NSManaged public var lastReviewedAt: Date?
    @NSManaged public var cardType: String?
    @NSManaged public var constraintsJSON: String?
    @NSManaged public var backgroundContextJSON: String?
    @NSManaged public var gradingRubricJSON: String?
    @NSManaged public var sourceRefsJSON: String?
    @NSManaged public var needsVerification: Bool
    @NSManaged public var verificationNote: String?
    @NSManaged public var tier: Int16
    @NSManaged public var dependsOnCardsJSON: String?
    @NSManaged public var cardState: String?
    @NSManaged public var generatedCardId: String?

    @NSManaged public var deck: Deck?
    @NSManaged public var concept: Concept?
    @NSManaged public var sessionResponses: NSSet?

    // MARK: - JSON Computed Properties

    var bulletPoints: [String] {
        get {
            guard let json = bulletPointsJSON,
                  let data = json.data(using: .utf8),
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return array
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                bulletPointsJSON = json
            }
        }
    }

    var constraints: [String] {
        get {
            guard let json = constraintsJSON,
                  let data = json.data(using: .utf8),
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return array
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                constraintsJSON = json
            }
        }
    }

    var backgroundContext: [String] {
        get {
            guard let json = backgroundContextJSON,
                  let data = json.data(using: .utf8),
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return array
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                backgroundContextJSON = json
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

    var dependsOnCards: [String] {
        get {
            guard let json = dependsOnCardsJSON,
                  let data = json.data(using: .utf8),
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return array
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                dependsOnCardsJSON = json
            }
        }
    }

    var effectiveCardState: String {
        return cardState ?? "available"
    }

    var gradingRubric: GradingRubric? {
        get {
            guard let json = gradingRubricJSON,
                  let data = json.data(using: .utf8) else {
                return nil
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try? decoder.decode(GradingRubric.self, from: data)
        }
        set {
            guard let value = newValue else {
                gradingRubricJSON = nil
                return
            }
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            if let data = try? encoder.encode(value),
               let json = String(data: data, encoding: .utf8) {
                gradingRubricJSON = json
            }
        }
    }
}

// MARK: Generated accessors for sessionResponses
extension Flashcard {

    @objc(addSessionResponsesObject:)
    @NSManaged public func addToSessionResponses(_ value: SessionResponse)

    @objc(removeSessionResponsesObject:)
    @NSManaged public func removeFromSessionResponses(_ value: SessionResponse)

    @objc(addSessionResponses:)
    @NSManaged public func addToSessionResponses(_ values: NSSet)

    @objc(removeSessionResponses:)
    @NSManaged public func removeFromSessionResponses(_ values: NSSet)
}

extension Flashcard: Identifiable {

}
