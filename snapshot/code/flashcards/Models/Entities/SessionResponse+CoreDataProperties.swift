import Foundation
import CoreData

extension SessionResponse {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SessionResponse> {
        return NSFetchRequest<SessionResponse>(entityName: "SessionResponse")
    }

    @NSManaged public var responseID: String?
    @NSManaged public var userAnswer: String?
    @NSManaged public var grade: Int16
    @NSManaged public var feedback: String?
    @NSManaged public var answeredAt: Date?
    @NSManaged public var confidence: Int16
    @NSManaged public var session: StudySession?
    @NSManaged public var flashcard: Flashcard?
}

extension SessionResponse: Identifiable {

}
