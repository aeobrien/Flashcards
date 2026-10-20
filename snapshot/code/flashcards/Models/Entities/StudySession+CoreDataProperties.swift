import Foundation
import CoreData

extension StudySession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StudySession> {
        return NSFetchRequest<StudySession>(entityName: "StudySession")
    }

    @NSManaged public var sessionID: String?
    @NSManaged public var startedAt: Date?
    @NSManaged public var completedAt: Date?
    @NSManaged public var deck: Deck?
    @NSManaged public var group: Group?
    @NSManaged public var isEarlyPractice: Bool
    @NSManaged public var responses: NSSet?

    var sortedResponses: [SessionResponse] {
        let set = responses as? Set<SessionResponse> ?? []
        return set.sorted { ($0.answeredAt ?? .distantPast) < ($1.answeredAt ?? .distantPast) }
    }

    var averageGrade: Double {
        let allResponses = sortedResponses
        guard !allResponses.isEmpty else { return 0 }
        let total = allResponses.reduce(0) { $0 + Int($1.grade) }
        return Double(total) / Double(allResponses.count)
    }
}

// MARK: Generated accessors for responses
extension StudySession {

    @objc(addResponsesObject:)
    @NSManaged public func addToResponses(_ value: SessionResponse)

    @objc(removeResponsesObject:)
    @NSManaged public func removeFromResponses(_ value: SessionResponse)

    @objc(addResponses:)
    @NSManaged public func addToResponses(_ values: NSSet)

    @objc(removeResponses:)
    @NSManaged public func removeFromResponses(_ values: NSSet)
}

extension StudySession: Identifiable {

}
